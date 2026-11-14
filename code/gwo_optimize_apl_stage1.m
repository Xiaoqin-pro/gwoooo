function result = gwo_optimize_apl_stage1(objective,lb,ub,opts)
% APL-weighted GWO plus one stage-1 mechanism: dlm1, dlm2, bdl_rank, bdl50, or ptlp.
opts=defaults(opts); lb=double(lb(:)'); ub=double(ub(:)');
if ~isa(objective,'function_handle'), error('Objective must be a function handle.'); end
if numel(lb)~=numel(ub) || any(~isfinite(lb)) || any(~isfinite(ub)) || any(ub<=lb)
    error('Bounds must be finite and ub > lb.');
end
if opts.PopulationSize<6 || opts.MaxFEs<opts.PopulationSize
    error('Require PopulationSize >= 6 and MaxFEs >= PopulationSize.');
end
variant=lower(char(opts.Variant));
valid={'dlm1','dlm2','bdl_rank','bdl50','ptlp','dlm2_bdl_rank','dlm2_bdl50'};
if ~any(strcmp(variant,valid)), error('Unknown stage-1 variant: %s',variant); end

rng(opts.Seed,'twister');
n=opts.PopulationSize; d=numel(lb); span=ub-lb;
pop=lb+rand(n,d).*span; fit=inf(n,1); fes=0;
bestFit=inf; bestX=pop(1,:); lastImproveFE=0;
for i=1:n
    fit(i)=evaluate(objective,pop(i,:)); fes=fes+1;
    if fit(i)<bestFit, bestFit=fit(i); bestX=pop(i,:); lastImproveFE=fes; end
end
initialDiv=mean(dimension_diversity(pop,span));
traceFE=ceil((1:100)'*opts.MaxFEs/100); traceDiv=nan(100,1); nextSample=1;
generation=0; patternEval=zeros(1,3); patternSuccess=zeros(1,3); archiveChoice=0;
bdlKSum=0; bdlCount=0; ptlpSelected=0; ptlpOpportunities=0;
dlmCount=0; dlmSuccess=0; doubleAttempt=0; doubleSuccess=0; fallback=0;
recoverySum=0; recoveryEvents=0;

while fes<opts.MaxFEs
    generation=generation+1; feStart=fes; dlmCountBefore=dlmCount;
    diversityBefore=mean(dimension_diversity(pop,span));
    [~,bestOrder]=sort(fit,'ascend');
    rankBest=zeros(n,1);
    for r=1:n, rankBest(bestOrder(r))=r; end
    rankWorst=n-rankBest+1;
    updateProbability=ptl_probabilities(rankWorst,n);
    if strcmp(variant,'ptlp'), updateProbability(bestOrder(1:opts.EliteCount))=0; end
    a=2-2*min(fes/opts.MaxFEs,1);
    nextPop=pop; nextFit=fit;
    dlmTargets=false(n,1);
    if any(strcmp(variant,{'dlm1','dlm2','dlm2_bdl_rank','dlm2_bdl50'}))
        number=ceil(opts.DLMFraction*(n-opts.EliteCount));
        dlmTargets(bestOrder(end-number+1:end))=true;
        dlmTargets(bestOrder(1:opts.EliteCount))=false;
    end
    for i=1:n
        if fes>=opts.MaxFEs, break; end
        ptlpOpportunities=ptlpOpportunities+1;
        if strcmp(variant,'ptlp')
            if rand>=updateProbability(i), continue; end
            ptlpSelected=ptlpSelected+1;
        end

        pool=[1:i-1,i+1:n]; guides=pool(randperm(numel(pool),5));
        [~,gOrder]=sort(fit(guides),'ascend'); guides=guides(gOrder);
        y=pop(i,:); fy=fit(i);
        if all(fit(guides)<fit(i))
            sharedR1=rand(5,d); sharedR2=rand(5,d);
            ratio=min(fes/opts.MaxFEs,1);
            c=[1,1-ratio/3,1/2-ratio/4,1/3-ratio/5,1/4-ratio/6];
            if any(strcmp(variant,{'bdl_rank','dlm2_bdl_rank'}))
                K=max(1,ceil(d*rankBest(i)/n)); mask=sample_mask(d,K);
                bdlKSum=bdlKSum+K; bdlCount=bdlCount+1;
            elseif any(strcmp(variant,{'bdl50','dlm2_bdl50'}))
                K=max(1,ceil(0.5*d)); mask=sample_mask(d,K);
                bdlKSum=bdlKSum+K; bdlCount=bdlCount+1;
            else
                mask=true(1,d);
            end
            archiveX=zeros(3,d); archiveFit=inf(3,1); improved=false;
            for m=1:3
                if fes>=opts.MaxFEs, break; end
                k=m+2;
                candidate=apl_weighted_gwo(pop(i,:),pop(guides(1:k),:),a,lb,ub, ...
                    sharedR1(1:k,:),sharedR2(1:k,:),c(1:k));
                candidate=pop(i,:)+mask.*(candidate-pop(i,:));
                candidate=min(max(candidate,lb),ub);
                cf=evaluate(objective,candidate); fes=fes+1;
                patternEval(m)=patternEval(m)+1;
                archiveX(m,:)=candidate; archiveFit(m)=cf;
                if cf<bestFit, bestFit=cf; bestX=candidate; lastImproveFE=fes; end
                if cf<fit(i)
                    y=candidate; fy=cf; improved=true; patternSuccess(m)=patternSuccess(m)+1;
                    break;
                end
            end
            if ~improved
                live=find(isfinite(archiveFit));
                [fy,j]=min(archiveFit(live)); y=archiveX(live(j),:); archiveChoice=archiveChoice+1;
            end
        end

        if dlmTargets(i) && fes<opts.MaxFEs
            [r1,r2]=select_difference_pair(n);
            step=laplace_factor(1,d,opts.LaplaceMu,opts.LaplaceSigma).*(pop(r1,:)-pop(r2,:));
            candidate=min(max(y+step,lb),ub);
            cf=evaluate(objective,candidate); fes=fes+1; dlmCount=dlmCount+1;
            if cf<bestFit, bestFit=cf; bestX=candidate; lastImproveFE=fes; end
            if cf<fy
                y=candidate; fy=cf; dlmSuccess=dlmSuccess+1;
                if any(strcmp(variant,{'dlm2','dlm2_bdl_rank','dlm2_bdl50'})) && fes<opts.MaxFEs
                    [r1,r2]=select_difference_pair(n);
                    step2=laplace_factor(1,d,opts.LaplaceMu,opts.LaplaceSigma).*(pop(r1,:)-pop(r2,:));
                    candidate2=min(max(y+step2,lb),ub);
                    cf2=evaluate(objective,candidate2); fes=fes+1; doubleAttempt=doubleAttempt+1;
                    if cf2<bestFit, bestFit=cf2; bestX=candidate2; lastImproveFE=fes; end
                    if cf2<fy, y=candidate2; fy=cf2; doubleSuccess=doubleSuccess+1; end
                end
            end
        end
        nextPop(i,:)=y; nextFit(i)=fy;
    end

    if fes==feStart && fes<opts.MaxFEs
        % Hard progress guard for a degenerate all-gated generation.
        [~,ord]=sort(fit,'ascend'); i=ord(end);
        candidate=apl_weighted_gwo(pop(i,:),pop(ord(1:3),:),a,lb,ub,[],[],ones(1,3));
        cf=evaluate(objective,candidate); fes=fes+1; fallback=fallback+1;
        nextPop(i,:)=candidate; nextFit(i)=cf;
        if cf<bestFit, bestFit=cf; bestX=candidate; lastImproveFE=fes; end
    end
    pop=nextPop; fit=nextFit;
    if dlmCount>dlmCountBefore
        diversityAfter=mean(dimension_diversity(pop,span));
        recoverySum=recoverySum+(diversityAfter-diversityBefore)/(diversityBefore+eps);
        recoveryEvents=recoveryEvents+1;
    end
    while nextSample<=100 && fes>=traceFE(nextSample)
        traceDiv(nextSample)=mean(dimension_diversity(pop,span)); nextSample=nextSample+1;
    end
end
if nextSample<=100, traceDiv(nextSample:end)=mean(dimension_diversity(pop,span)); end

result=struct('BestPosition',bestX,'BestFitness',bestFit,'MeanFitness',mean(fit), ...
    'StdFitness',std(fit),'FEs',fes,'Generations',generation,'Variant',variant, ...
    'Seed',opts.Seed,'Options',opts,'Trace',struct('DiversityFE',traceFE,'Diversity',traceDiv));
result.Diagnostics=struct('PatternEvaluations',patternEval,'PatternSuccesses',patternSuccess, ...
    'ArchiveSelections',archiveChoice,'BDLMeanK',bdlKSum/max(bdlCount,1), ...
    'PTLPUpdateRate',ptlpSelected/max(ptlpOpportunities,1), ...
    'DLMCount',dlmCount,'DLMSuccess',dlmSuccess,'DoubleDLMCount',doubleAttempt, ...
    'DoubleDLMSuccess',doubleSuccess,'FallbackEvaluations',fallback, ...
    'DiversityInitial',initialDiv,'DiversityFinal',traceDiv(end), ...
    'DiversityMin',min(traceDiv),'DiversityRecoveryMean', ...
    recoverySum/max(recoveryEvents,1),'DiversityRecoveryEvents',recoveryEvents);
end

function opts=defaults(opts)
if nargin<1 || isempty(opts), opts=struct(); end
def=struct('PopulationSize',30,'Seed',1,'Variant','dlm1', ...
    'DLMFraction',0.20,'EliteCount',3,'LaplaceMu',0.6,'LaplaceSigma',0.3);
f=fieldnames(def);
for j=1:numel(f), if ~isfield(opts,f{j}) || isempty(opts.(f{j})), opts.(f{j})=def.(f{j}); end, end
if ~isfield(opts,'MaxFEs') || isempty(opts.MaxFEs) || ...
        opts.MaxFEs~=floor(opts.MaxFEs) || opts.MaxFEs<opts.PopulationSize
    error('MaxFEs must be an integer >= PopulationSize.');
end
end

function value=evaluate(objective,x)
value=objective(x);
if ~isscalar(value) || ~isreal(value) || ~isfinite(value)
    error('Objective callback must return one finite real scalar.');
end
value=double(value);
end

function candidate=apl_weighted_gwo(x,guides,a,lb,ub,R1,R2,c)
k=size(guides,1); d=numel(x);
if isempty(R1), R1=rand(k,d); R2=rand(k,d); end
Z=zeros(k,d);
for j=1:k
    leader=guides(j,:); A=2*a*R1(j,:)-a; C=2*R2(j,:);
    Z(j,:)=leader-A.*abs(C.*leader-x);
end
candidate=(c*Z)/sum(c);
candidate=min(max(candidate,lb),ub);
end

function mask=sample_mask(d,K)
mask=false(1,d); mask(randperm(d,min(d,K)))=true;
end

function probability=ptl_probabilities(rankWorst,n)
w=exp(-((rankWorst-1).^2)./(8*pi*n^2))./(sqrt(2*pi)*n);
den=max(w)-min(w);
if den<=0, probability=zeros(size(w)); else, probability=(w-min(w))./den; end
end

function [r1,r2]=select_difference_pair(n)
pair=randperm(n,2); r1=pair(1); r2=pair(2);
end

function z=laplace_factor(sz1,sz2,mu,sigma)
u=rand(sz1,sz2)-0.5;
z=mu-sigma.*sign(u).*log(max(1-2*abs(u),realmin));
end

function d=dimension_diversity(pop,span)
d=std(pop,0,1)./span;
end
