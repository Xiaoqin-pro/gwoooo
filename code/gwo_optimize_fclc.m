function result = gwo_optimize_fclc(objective,lb,ub,opts)
%GWO_OPTIMIZE_FCLC GWO with sparse counterfactual leader-channel credit.
% Modes: 'fclc' (per-follower credit), 'gclc' (shared credit), 'static'.
% The alpha/beta/delta agents keep the standard equal-weight GWO update.

if nargin<4 || isempty(opts), opts=struct(); end
opts=apply_defaults(opts);
if ~isa(objective,'function_handle')
    error('gwo_optimize_fclc:Objective','objective must be a function handle.');
end
lb=double(lb(:)'); ub=double(ub(:)');
if isempty(lb) || numel(lb)~=numel(ub) || any(~isfinite(lb)) || ...
        any(~isfinite(ub)) || any(ub<=lb)
    error('gwo_optimize_fclc:Bounds','Bounds must be finite vectors with ub > lb.');
end

rng(opts.Seed,'twister');
N=opts.PopulationSize; D=numel(lb); span=ub-lb;
pop=lb+rand(N,D).*span; fit=inf(N,1); FEs=0;
for i=1:N
    fit(i)=evaluate_one(objective,pop(i,:)); FEs=FEs+1;
end
[bestEvaluatedFit,bestEvaluatedIndex]=min(fit);
bestEvaluatedX=pop(bestEvaluatedIndex,:);
bestPropagatedFit=bestEvaluatedFit; bestPropagatedX=bestEvaluatedX;

credit=zeros(N,3); globalCredit=zeros(1,3);
lastProbeGeneration=zeros(N,3); probeCursor=1;
wasOmega=false(N,1); generation=0;
probeCount=0; probeCountByRole=zeros(1,3); probeGainByRole=zeros(1,3);
probeGainSquareByRole=zeros(1,3); probeSamplesByRole=zeros(1,3);
traceFE=ceil((1:100)'*opts.MaxFEs/100);
traceBest=nan(100,1); tracePropagatedBest=nan(100,1);
traceMeanWeights=nan(100,3); traceWeightSpread=nan(100,1);
traceProbeCount=zeros(100,1); sampleIndex=1;
bestProbeFit=inf; bestProbeX=nan(1,D);

while FEs<opts.MaxFEs
    generation=generation+1;
    [~,order]=sort(fit,'ascend');
    leaders=order(1:3); omega=true(N,1); omega(leaders)=false;
    enteringOmega=omega & ~wasOmega;
    if strcmp(opts.Mode,'fclc') && any(enteringOmega)
        credit(enteringOmega,:)=0;
    end
    wasOmega=omega;
    scale=max(local_iqr(fit),1e-12*max(1,abs(median(fit))));
    a=2-2*min(FEs/opts.MaxFEs,1);

    weights=zeros(N,3);
    weights(leaders,:)=repmat([1/3 1/3 1/3],3,1);
    omegaIDs=find(omega);
    switch opts.Mode
        case 'fclc'
            for q=1:numel(omegaIDs)
                i=omegaIDs(q); weights(i,:)=credit_weights(credit(i,:),opts);
            end
        case 'gclc'
            sharedWeights=credit_weights(globalCredit,opts);
            weights(omega,:)=repmat(sharedWeights,numel(omegaIDs),1);
        case 'static'
            weights(omega,:)=repmat(opts.FixedWeights,numel(omegaIDs),1);
    end

    probePlan=zeros(N,1);
    if ~strcmp(opts.Mode,'static') && opts.ProbeFraction>0
        m=min(numel(omegaIDs),ceil(opts.ProbeFraction*numel(omegaIDs)));
        [probePlan,probeCursor]=make_probe_plan(omega,lastProbeGeneration,probeCursor,m);
    end

    nextPop=pop; nextFit=fit;
    pendingFollower=zeros(0,1); pendingRole=zeros(0,1); pendingGain=zeros(0,1);
    evaluatedInGeneration=false; generationProbeCount=0;
    generationWeightMean=mean(weights(omega,:),1);
    generationWeightSpread=mean(std(weights(omega,:),0,1));

    for i=1:N
        if FEs>=opts.MaxFEs, break; end
        r1=rand(3,D); r2=rand(3,D);
        Z=leader_proposals(pop(i,:),pop(leaders,:),a,r1,r2);
        candidate=clamp_box(weights(i,:)*Z,lb,ub);
        candidateFit=evaluate_one(objective,candidate); FEs=FEs+1;
        evaluatedInGeneration=true;
        nextPop(i,:)=candidate; nextFit(i)=candidateFit;
        if candidateFit<bestEvaluatedFit
            bestEvaluatedFit=candidateFit; bestEvaluatedX=candidate;
        end
        if candidateFit<bestPropagatedFit
            bestPropagatedFit=candidateFit; bestPropagatedX=candidate;
        end

        role=probePlan(i);
        if role>0 && FEs<opts.MaxFEs
            otherRoles=setdiff(1:3,role,'stable');
            cfWeights=zeros(1,3);
            cfWeights(otherRoles)=weights(i,otherRoles)./sum(weights(i,otherRoles));
            counterCandidate=clamp_box(cfWeights*Z,lb,ub);
            counterFit=evaluate_one(objective,counterCandidate); FEs=FEs+1;
            generationProbeCount=generationProbeCount+1; probeCount=probeCount+1;
            probeCountByRole(role)=probeCountByRole(role)+1;
            if counterFit<bestEvaluatedFit
                bestEvaluatedFit=counterFit; bestEvaluatedX=counterCandidate;
            end
            if counterFit<bestProbeFit
                bestProbeFit=counterFit; bestProbeX=counterCandidate;
            end
            mc=clip01((counterFit-candidateFit)/scale);
            pendingFollower(end+1,1)=i; %#ok<AGROW>
            pendingRole(end+1,1)=role; %#ok<AGROW>
            pendingGain(end+1,1)=mc; %#ok<AGROW>
            probeGainByRole(role)=probeGainByRole(role)+mc;
            probeGainSquareByRole(role)=probeGainSquareByRole(role)+mc.^2;
            probeSamplesByRole(role)=probeSamplesByRole(role)+1;
            lastProbeGeneration(i,role)=generation;
        end
    end

    % All candidates in a generation use the same credit snapshot.
    if ~isempty(pendingGain)
        if strcmp(opts.Mode,'fclc')
            for q=1:numel(pendingGain)
                i=pendingFollower(q); role=pendingRole(q);
                credit(i,role)=(1-opts.CreditLearningRate)*credit(i,role)+ ...
                    opts.CreditLearningRate*pendingGain(q);
            end
        elseif strcmp(opts.Mode,'gclc')
            for role=1:3
                gains=pendingGain(pendingRole==role);
                if ~isempty(gains)
                    meanGain=mean(gains);
                    globalCredit(role)=(1-opts.CreditLearningRate)*globalCredit(role)+ ...
                        opts.CreditLearningRate*meanGain;
                end
            end
        end
    end

    pop=nextPop; fit=nextFit;
    while sampleIndex<=100 && FEs>=traceFE(sampleIndex)
        traceBest(sampleIndex)=bestEvaluatedFit;
        tracePropagatedBest(sampleIndex)=bestPropagatedFit;
        traceMeanWeights(sampleIndex,:)=generationWeightMean;
        traceWeightSpread(sampleIndex)=generationWeightSpread;
        traceProbeCount(sampleIndex)=generationProbeCount;
        sampleIndex=sampleIndex+1;
    end
    if ~evaluatedInGeneration, break; end
end

if sampleIndex<=100
    traceBest(sampleIndex:end)=bestEvaluatedFit;
    tracePropagatedBest(sampleIndex:end)=bestPropagatedFit;
    if generation>0
        traceMeanWeights(sampleIndex:end,:)=generationWeightMean;
        traceWeightSpread(sampleIndex:end)=generationWeightSpread;
        traceProbeCount(sampleIndex:end)=generationProbeCount;
    end
end

[~,order]=sort(fit,'ascend'); omega=true(N,1); omega(order(1:3))=false;
if strcmp(opts.Mode,'fclc')
    finalWeights=zeros(N,3);
    omegaIDs=find(omega);
    for q=1:numel(omegaIDs)
        i=omegaIDs(q);
        finalWeights(i,:)=credit_weights(credit(i,:),opts);
    end
elseif strcmp(opts.Mode,'gclc')
    finalWeights=zeros(N,3);
    finalWeights(omega,:)=repmat(credit_weights(globalCredit,opts),sum(omega),1);
else
    finalWeights=zeros(N,3); finalWeights(omega,:)=repmat(opts.FixedWeights,sum(omega),1);
end

result=struct('BestPosition',bestEvaluatedX,'BestFitness',bestEvaluatedFit, ...
    'BestPropagatedPosition',bestPropagatedX,'BestPropagatedFitness',bestPropagatedFit, ...
    'BestProbePosition',bestProbeX,'BestProbeFitness',bestProbeFit, ...
    'MeanFitness',mean(fit),'StdFitness',std(fit),'FEs',FEs, ...
    'Generations',generation,'Seed',opts.Seed,'Options',opts, ...
    'Trace',struct('FE',traceFE,'BestFitness',traceBest, ...
    'BestPropagatedFitness',tracePropagatedBest,'MeanWeights',traceMeanWeights, ...
    'WeightSpread',traceWeightSpread,'ProbeCount',traceProbeCount));
result.Diagnostics=struct('Mode',opts.Mode,'ProbeCount',probeCount, ...
    'ProbeCountByRole',probeCountByRole,'MeanProbeContribution', ...
    probeGainByRole./max(probeSamplesByRole,1), ...
    'ProbeContributionStd',sqrt(max(0,probeGainSquareByRole./max(probeSamplesByRole,1)- ...
    (probeGainByRole./max(probeSamplesByRole,1)).^2)), ...
    'FinalCredit',credit,'FinalGlobalCredit',globalCredit, ...
    'FinalFollowerWeights',finalWeights,'FinalOmegaMask',omega, ...
    'MeanFinalWeight',mean(finalWeights(omega,:),1), ...
    'FinalWeightSpread',mean(std(finalWeights(omega,:),0,1)));
end

function opts=apply_defaults(opts)
def=struct('PopulationSize',30,'Seed',1,'Mode','fclc','ProbeFraction',0.1, ...
    'CreditLearningRate',0.2,'SoftmaxTemperature',1,'MinWeight',0.05, ...
    'FixedWeights',[0.6 0.3 0.1]);
names=fieldnames(def);
for k=1:numel(names)
    if ~isfield(opts,names{k}) || isempty(opts.(names{k}))
        opts.(names{k})=def.(names{k});
    end
end
if ~isfield(opts,'MaxFEs') || isempty(opts.MaxFEs) || ...
        opts.MaxFEs~=floor(opts.MaxFEs) || opts.MaxFEs<opts.PopulationSize
    error('gwo_optimize_fclc:Budget','MaxFEs must be an integer >= PopulationSize.');
end
if opts.PopulationSize<4 || opts.PopulationSize~=floor(opts.PopulationSize)
    error('gwo_optimize_fclc:PopulationSize','PopulationSize must be an integer >= 4.');
end
if ~any(strcmpi(opts.Mode,{'fclc','gclc','static'}))
    error('gwo_optimize_fclc:Mode','Mode must be fclc, gclc, or static.');
end
opts.Mode=lower(char(opts.Mode));
if opts.ProbeFraction<0 || opts.ProbeFraction>1 || ...
        opts.CreditLearningRate<0 || opts.CreditLearningRate>1 || ...
        opts.SoftmaxTemperature<=0 || opts.MinWeight<0 || opts.MinWeight>=1/3
    error('gwo_optimize_fclc:Options','Invalid probe, credit, temperature, or weight-floor option.');
end
if numel(opts.FixedWeights)~=3 || any(opts.FixedWeights<0) || sum(opts.FixedWeights)<=0
    error('gwo_optimize_fclc:FixedWeights','FixedWeights must be three nonnegative values with positive sum.');
end
opts.FixedWeights=opts.FixedWeights(:)'./sum(opts.FixedWeights);
end

function value=evaluate_one(objective,x)
value=objective(x);
if ~isscalar(value) || ~isreal(value) || ~isfinite(value)
    error('gwo_optimize_fclc:ObjectiveValue','objective must return one finite real scalar.');
end
value=double(value);
end

function Z=leader_proposals(x,leaders,a,R1,R2)
Z=zeros(3,numel(x));
for l=1:3
    A=2*a.*R1(l,:)-a;
    C=2.*R2(l,:);
    Z(l,:)=leaders(l,:)-A.*abs(C.*leaders(l,:)-x);
end
end

function x=clamp_box(x,lb,ub)
x=min(max(x,lb),ub);
end

function w=credit_weights(H,opts)
z=H(:)'./opts.SoftmaxTemperature;
z=z-max(z);
q=exp(z); q=q./sum(q);
w=opts.MinWeight+(1-3*opts.MinWeight).*q;
end

function [plan,cursor]=make_probe_plan(omega,lastProbeGeneration,cursor,m)
N=numel(omega); plan=zeros(N,1); used=false(N,1);
for q=1:m
    bestGeneration=inf; bestDistance=inf; bestIndex=0; bestWolf=0; bestRole=0;
    for i=find(omega(:))'
        if used(i), continue; end
        for role=1:3
            idx=(i-1)*3+role;
            last=lastProbeGeneration(i,role);
            distance=mod(idx-cursor,N*3);
            if last<bestGeneration || (last==bestGeneration && distance<bestDistance)
                bestGeneration=last; bestDistance=distance;
                bestIndex=idx; bestWolf=i; bestRole=role;
            end
        end
    end
    if bestWolf==0, break; end
    plan(bestWolf)=bestRole; used(bestWolf)=true;
    cursor=mod(bestIndex,N*3)+1;
end
end

function q=local_iqr(x)
x=sort(x(:)); n=numel(x);
if n<2, q=0; return; end
q3=interp1(1:n,x,1+0.75*(n-1),'linear');
q1=interp1(1:n,x,1+0.25*(n-1),'linear');
q=q3-q1;
end

function y=clip01(x)
y=min(max(x,-1),1);
end
