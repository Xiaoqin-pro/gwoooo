function result = gwo_optimize_fad(objective,lb,ub,opts)
%GWO_OPTIMIZE_FAD Feedback-Adaptive Dual-layer GWO with weighted APL core.
% This is the first fixed-parameter research prototype, not a confirmed method.

opts=defaults(opts); lb=double(lb(:)'); ub=double(ub(:)');
if ~isa(objective,'function_handle'), error('Objective must be a function handle.'); end
if numel(lb)~=numel(ub) || any(~isfinite(lb)) || any(~isfinite(ub)) || any(ub<=lb)
    error('Bounds must be finite and ub > lb.');
end
if opts.PopulationSize<6 || opts.MaxFEs<opts.PopulationSize
    error('Require PopulationSize >= 6 and MaxFEs >= PopulationSize.');
end

rng(opts.Seed,'twister');
N=opts.PopulationSize; D=numel(lb); span=ub-lb;
X=lb+rand(N,D).*span; fit=inf(N,1); FEs=0;
gBest=inf; gBestX=X(1,:); c=zeros(N,1); state=zeros(N,1);
for i=1:N
    fit(i)=evaluate(objective,X(i,:)); FEs=FEs+1;
    if fit(i)<gBest, gBest=fit(i); gBestX=X(i,:); end
end

D0=dimension_diversity(X,span);
successMemory=zeros(1,D); failureMemory=zeros(1,D);
selectionCount=zeros(1,D); selectionOpportunity=0; totalK=0; kCount=0;
traceFE=ceil((1:100)'*opts.MaxFEs/100);
traceDiv=nan(100,1); traceState=nan(100,1); traceK=nan(100,1);
traceDLMtargets=nan(100,1); sampleIndex=1;
gen=0; aplGateAttempts=0; aplGatePasses=0; patternEval=zeros(1,3);
patternSuccess=zeros(1,3); fallbackCount=0; dlmTargetCount=0;
dlmAttemptCount=0; dlmSuccessCount=0; dlmSecondCount=0; dlmSecondSuccessCount=0;
targetCountHistory=[];

while FEs<opts.MaxFEs
    gen=gen+1; FEstart=FEs;
    [~,bestOrder]=sort(fit,'ascend');
    rankBest=zeros(N,1);
    for r=1:N, rankBest(bestOrder(r))=r; end
    H=min(c./opts.StagnationWindow,1);
    R=(rankBest-1)./max(N-1,1);
    rawState=opts.StateWeight.*H+(1-opts.StateWeight).*R;
    state=opts.StateSmoothing.*state+(1-opts.StateSmoothing).*rawState;

    currentDimDiv=dimension_diversity(X,span);
    collapse=zeros(1,D);
    validD0=D0>opts.Epsilon;
    collapse(validD0)=clip01(1-currentDimDiv(validD0)./(D0(validD0)+opts.Epsilon));
    Q=(opts.BetaPrior+successMemory)./(2*opts.BetaPrior+successMemory+failureMemory);
    nonElite=bestOrder(opts.EliteCount+1:end);
    rho=opts.DLMMinFraction+(opts.DLMMaxFraction-opts.DLMMinFraction)*mean(state(nonElite));
    targetCount=min(numel(nonElite),max(1,ceil(numel(nonElite)*rho)));
    targetCountHistory(end+1,1)=targetCount; %#ok<AGROW>
    [~,stateOrder]=sort(state(nonElite),'descend');
    dlmTargets=false(N,1); dlmTargets(nonElite(stateOrder(1:targetCount)))=true;

    IQR=max(local_iqr(fit),opts.Epsilon);
    a=2-2*min(FEs/opts.MaxFEs,1);
    nextX=X; nextFit=fit; nextC=c;
    successCredit=zeros(1,D); failureCredit=zeros(1,D);
    generationSelections=zeros(1,D); generationK=0; generationKCount=0;
    generationFallback=0; generationDLMtargets=sum(dlmTargets);
    evaluatedInGen=false;

    for i=1:N
        if FEs>=opts.MaxFEs, break; end
        K=min(D,max(1,ceil(D*(0.5+0.4*state(i)))));
        P=((1-state(i)).*Q+state(i).*collapse)+opts.Epsilon;
        P=P./sum(P);
        P=(1-opts.UniformFloor).*P+opts.UniformFloor/D;
        mask=weighted_sample(P,K);
        oldX=X(i,:); oldFit=fit(i); y=oldX; fy=oldFit; didUpdate=false;
        aplGateAttempts=aplGateAttempts+1;
        pool=[1:i-1,i+1:N];
        guides=pool(randperm(numel(pool),5));
        [~,gOrder]=sort(fit(guides),'ascend'); guides=guides(gOrder);

        if all(fit(guides)<fit(i))
            aplGatePasses=aplGatePasses+1;
            sharedR1=rand(5,D); sharedR2=rand(5,D);
            ratio=min(FEs/opts.MaxFEs,1);
            coeff=[1,1-ratio/3,1/2-ratio/4,1/3-ratio/5,1/4-ratio/6];
            archiveX=zeros(3,D); archiveFit=inf(3,1); improved=false;
            for m=1:3
                if FEs>=opts.MaxFEs, break; end
                k=m+2;
                z=weighted_apl_gwo(oldX,X(guides(1:k),:),a,lb,ub, ...
                    sharedR1(1:k,:),sharedR2(1:k,:),coeff(1:k));
                candidate=oldX+mask.*(z-oldX);
                candidate=min(max(candidate,lb),ub);
                cf=evaluate(objective,candidate); FEs=FEs+1; evaluatedInGen=true;
                patternEval(m)=patternEval(m)+1;
                archiveX(m,:)=candidate; archiveFit(m)=cf;
                [successCredit,failureCredit]=credit_update(successCredit,failureCredit, ...
                    oldX,candidate,oldFit,cf,mask,IQR,opts.Epsilon);
                if cf<gBest, gBest=cf; gBestX=candidate; end
                if cf<oldFit
                    y=candidate; fy=cf; improved=true;
                    patternSuccess(m)=patternSuccess(m)+1;
                    break;
                end
            end
            if ~improved
                live=find(isfinite(archiveFit));
                [fy,j]=min(archiveFit(live)); y=archiveX(live(j),:);
            end
            didUpdate=true;
        elseif state(i)>=median(state)
            % High-stagnation APL gate fallback: ordinary three-leader GWO update,
            % restricted by the same dimension mask. Standard GWO applies this move.
            guidesGWO=X(bestOrder(1:3),:);
            z=weighted_apl_gwo(oldX,guidesGWO,a,lb,ub,[],[],ones(1,3));
            candidate=oldX+mask.*(z-oldX);
            candidate=min(max(candidate,lb),ub);
            if FEs<opts.MaxFEs
                cf=evaluate(objective,candidate); FEs=FEs+1; evaluatedInGen=true;
                [successCredit,failureCredit]=credit_update(successCredit,failureCredit, ...
                    oldX,candidate,oldFit,cf,mask,IQR,opts.Epsilon);
                if cf<gBest, gBest=cf; gBestX=candidate; end
                y=candidate; fy=cf; didUpdate=true; fallbackCount=fallbackCount+1;
            end
        end

        if dlmTargets(i) && FEs<opts.MaxFEs
            step=adaptive_dlm_step(X,mask,state(i),collapse,span,opts,FEs);
            candidate=min(max(y+step,lb),ub);
            cf=evaluate(objective,candidate); FEs=FEs+1; evaluatedInGen=true;
            dlmAttemptCount=dlmAttemptCount+1;
            didUpdate=true;
            [successCredit,failureCredit]=credit_update(successCredit,failureCredit, ...
                y,candidate,fy,cf,mask,IQR,opts.Epsilon);
            if cf<gBest, gBest=cf; gBestX=candidate; end
            if cf<fy
                y=candidate; fy=cf; didUpdate=true; dlmSuccessCount=dlmSuccessCount+1;
                if FEs<opts.MaxFEs
                    step2=adaptive_dlm_step(X,mask,state(i),collapse,span,opts,FEs);
                    candidate2=min(max(y+step2,lb),ub);
                    cf2=evaluate(objective,candidate2); FEs=FEs+1; evaluatedInGen=true;
                    dlmSecondCount=dlmSecondCount+1;
                    [successCredit,failureCredit]=credit_update(successCredit,failureCredit, ...
                        y,candidate2,fy,cf2,mask,IQR,opts.Epsilon);
                    if cf2<gBest, gBest=cf2; gBestX=candidate2; end
                    if cf2<fy
                        y=candidate2; fy=cf2; dlmSecondSuccessCount=dlmSecondSuccessCount+1;
                    end
                end
            end
        end

        if didUpdate
            generationSelections=generationSelections+double(mask);
            selectionOpportunity=selectionOpportunity+1;
            generationK=generationK+K; generationKCount=generationKCount+1;
            if fy<oldFit, nextC(i)=0; else, nextC(i)=c(i)+1; end
        else
            nextC(i)=c(i)+1;
        end
        nextX(i,:)=y; nextFit(i)=fy;
    end

    if ~evaluatedInGen && FEs<opts.MaxFEs
        % Guarantee FE progress on a fully gated/tied generation.
        [~,ord]=sort(fit,'ascend'); i=ord(end);
        K=min(D,max(1,ceil(D*(0.5+0.4*state(i)))));
        P=((1-state(i)).*Q+state(i).*collapse)+opts.Epsilon; P=P./sum(P);
        P=(1-opts.UniformFloor).*P+opts.UniformFloor/D;
        mask=weighted_sample(P,K);
        z=weighted_apl_gwo(X(i,:),X(ord(1:3),:),a,lb,ub,[],[],ones(1,3));
        candidate=min(max(X(i,:)+mask.*(z-X(i,:)),lb),ub);
        cf=evaluate(objective,candidate); FEs=FEs+1; generationFallback=1;
        [successCredit,failureCredit]=credit_update(successCredit,failureCredit, ...
            X(i,:),candidate,fit(i),cf,mask,IQR,opts.Epsilon);
        if cf<gBest, gBest=cf; gBestX=candidate; end
        nextX(i,:)=candidate; nextFit(i)=cf;
        if cf<fit(i), nextC(i)=0; else, nextC(i)=c(i)+1; end
        generationSelections=generationSelections+double(mask);
        selectionOpportunity=selectionOpportunity+1; generationK=generationK+K; generationKCount=generationKCount+1;
        fallbackCount=fallbackCount+1;
    end

    % Aggregate feedback once per generation so wolf order does not affect Q_j.
    successMemory=opts.MemoryForgetting.*successMemory+successCredit;
    failureMemory=opts.MemoryForgetting.*failureMemory+failureCredit;
    selectionCount=selectionCount+generationSelections;
    totalK=totalK+generationK; kCount=kCount+generationKCount;
    X=nextX; fit=nextFit; c=nextC;
    while sampleIndex<=100 && FEs>=traceFE(sampleIndex)
        traceDiv(sampleIndex)=mean(dimension_diversity(X,span));
        traceState(sampleIndex)=mean(state);
        traceK(sampleIndex)=generationK/max(generationKCount,1);
        traceDLMtargets(sampleIndex)=generationDLMtargets;
        sampleIndex=sampleIndex+1;
    end
end
if sampleIndex<=100
    traceDiv(sampleIndex:end)=mean(dimension_diversity(X,span));
    traceState(sampleIndex:end)=mean(state);
    traceK(sampleIndex:end)=totalK/max(kCount,1);
    traceDLMtargets(sampleIndex:end)=generationDLMtargets;
end
finalDiv=dimension_diversity(X,span);
Qfinal=(opts.BetaPrior+successMemory)./(2*opts.BetaPrior+successMemory+failureMemory);
Cfinal=zeros(1,D); good=D0>opts.Epsilon;
Cfinal(good)=clip01(1-finalDiv(good)./(D0(good)+opts.Epsilon));
result=struct('BestPosition',gBestX,'BestFitness',gBest,'MeanFitness',mean(fit), ...
    'StdFitness',std(fit),'FEs',FEs,'Generations',gen,'Seed',opts.Seed, ...
    'Options',opts,'Trace',struct('FE',traceFE,'Diversity',traceDiv, ...
    'MeanState',traceState,'MeanK',traceK,'DLMTargetCount',traceDLMtargets));
result.Diagnostics=struct('MeanFinalState',mean(state),'MaxFinalState',max(state), ...
    'MeanK',totalK/max(kCount,1),'DimensionSelectionCount',selectionCount, ...
    'DimensionSelectionRate',selectionCount/max(selectionOpportunity,1), ...
    'DimensionSuccessCredit',successMemory,'DimensionFailureCredit',failureMemory, ...
    'DimensionSuccessRate',Qfinal,'DimensionCollapse',Cfinal,'InitialDimensionDiversity',D0, ...
    'FinalDimensionDiversity',finalDiv,'APLGateAttempts',aplGateAttempts, ...
    'APLGatePasses',aplGatePasses,'APLGatePassRate',aplGatePasses/max(aplGateAttempts,1), ...
    'PatternEvaluations',patternEval,'PatternSuccesses',patternSuccess, ...
    'DLMSelectedMean',mean(targetCountHistory), ...
    'DLMAttempts',dlmAttemptCount,'DLMSuccesses',dlmSuccessCount, ...
    'DLMFirstSuccessRate',dlmSuccessCount/max(dlmAttemptCount,1), ...
    'DLMSecondAttempts',dlmSecondCount,'DLMSecondSuccesses',dlmSecondSuccessCount, ...
    'DLMSecondSuccessRate',dlmSecondSuccessCount/max(dlmSecondCount,1), ...
    'FallbackCount',fallbackCount,'DimensionMemoryUpdates',selectionOpportunity);
end
function opts=defaults(opts)
if nargin<1 || isempty(opts), opts=struct(); end
def=struct('PopulationSize',30,'Seed',1,'EliteCount',3, ...
    'StagnationWindow',5,'StateWeight',0.7,'StateSmoothing',0.7, ...
    'MemoryForgetting',0.95,'UniformFloor',0.1,'DLMMinFraction',0.05, ...
    'DLMMaxFraction',0.20,'LaplaceMu',0.6,'LaplaceSigmaMin',0.3, ...
    'LaplaceSigmaMax',0.6,'RecoveryScale',0.03,'RecoveryExponent',1, ...
    'BetaPrior',1,'Epsilon',1e-12,'TargetMaskEliteCount',3);
names=fieldnames(def);
for k=1:numel(names)
    if ~isfield(opts,names{k}) || isempty(opts.(names{k}))
        opts.(names{k})=def.(names{k});
    end
end
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

function mask=weighted_sample(prob,K)
p=max(prob(:)',0); mask=false(size(p));
for q=1:min(K,numel(p))
    total=sum(p);
    if total<=0
        available=find(~mask); idx=available(randi(numel(available)));
    else
        threshold=rand*total; idx=find(cumsum(p)>=threshold,1,'first');
        if isempty(idx), idx=find(p>0,1,'last'); end
    end
    mask(idx)=true; p(idx)=0;
end
end

function candidate=weighted_apl_gwo(x,guides,a,lb,ub,R1,R2,weights)
k=size(guides,1); d=numel(x);
if isempty(R1), R1=rand(k,d); R2=rand(k,d); end
Z=zeros(k,d);
for j=1:k
    leader=guides(j,:); A=2*a*R1(j,:)-a; C=2*R2(j,:);
    Z(j,:)=leader-A.*abs(C.*leader-x);
end
candidate=(weights*Z)/sum(weights);
candidate=min(max(candidate,lb),ub);
end

function [successCredit,failureCredit]=credit_update(successCredit,failureCredit, ...
    x,y,fx,fy,mask,iqrFitness,epsilon)
delta=abs(y-x).*mask; total=sum(delta);
if total<=epsilon, return; end
w=delta./(total+epsilon);
gain=clip01((fx-fy)/(iqrFitness+epsilon));
successCredit=successCredit+gain.*w;
failureCredit=failureCredit+(1-gain).*w;
end

function step=adaptive_dlm_step(X,mask,state,collapse,span,opts,FEs)
N=size(X,1); pair=randperm(N,2);
sigma=opts.LaplaceSigmaMin+(opts.LaplaceSigmaMax-opts.LaplaceSigmaMin)*state;
u=rand(1,size(X,2))-0.5;
lap=opts.LaplaceMu-sigma.*sign(u).*log(max(1-2*abs(u),realmin));
diffStep=lap.*(X(pair(1),:)-X(pair(2),:));
kappa=opts.RecoveryScale*(1-min(FEs/opts.MaxFEs,1))^opts.RecoveryExponent;
v=rand(1,size(X,2))-0.5;
xi=-sign(v).*log(max(1-2*abs(v),realmin));
recovery=kappa.*state.*collapse.*span.*xi;
step=(diffStep+recovery).*mask;
end

function diversity=dimension_diversity(X,span)
diversity=std(X,0,1)./span;
end

function q=local_iqr(x)
x=sort(x(:)); n=numel(x);
q3=interp1(1:n,x,1+0.75*(n-1),'linear');
q1=interp1(1:n,x,1+0.25*(n-1),'linear');
q=q3-q1;
end

function y=clip01(x)
y=min(max(x,0),1);
end
