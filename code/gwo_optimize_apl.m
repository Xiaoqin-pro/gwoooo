function result = gwo_optimize_apl(objective, lb, ub, opts)
%GWO_OPTIMIZE_APL APLPSO-inspired exemplar screening and adaptive GWO modes.
% Variants: apl_v2, apl_weighted, tournament_apl_v2,
%           tournament_apl_weighted.
% This is an explicit GWO transfer, not the original PSO position equation.

if nargin < 4 || isempty(opts), opts = struct(); end
opts = fill_defaults(opts);
if ~isa(objective,'function_handle')
    error('gwo_optimize_apl:Objective','objective must be a function handle.');
end
lb = double(lb(:)'); ub = double(ub(:)');
if isempty(lb) || numel(lb) ~= numel(ub) || any(~isfinite(lb)) || ...
        any(~isfinite(ub)) || any(ub <= lb)
    error('gwo_optimize_apl:Bounds','Bounds must be finite and ub > lb.');
end
if opts.PopulationSize < 6
    error('gwo_optimize_apl:PopulationSize','APL variants require at least 6 wolves.');
end
if opts.MaxFEs < opts.PopulationSize
    error('gwo_optimize_apl:MaxFEs','MaxFEs must be >= PopulationSize.');
end
variant = lower(char(opts.Variant));
valid = {'apl_v2','apl_weighted','tournament_apl_v2','tournament_apl_weighted'};
if ~any(strcmp(variant,valid))
    error('gwo_optimize_apl:Variant','Unknown APL variant: %s',variant);
end
useTournament = startsWith(variant,'tournament_');
useWeights = endsWith(variant,'weighted');

rng(opts.Seed,'twister');
n = opts.PopulationSize; d = numel(lb); span = ub-lb;
pop = lb + rand(n,d).*span;
fit = zeros(n,1); fes = 0;
for i=1:n
    fit(i) = evaluate_one(objective,pop(i,:)); fes = fes+1;
end
[bestFit,bestI] = min(fit); bestX = pop(bestI,:);
traceFEs = fes; traceBest = bestFit; traceDiv = population_diversity(pop,span);
generation = 0;
gateAttempts=0; gatePasses=0; patternEvals=zeros(1,3); patternSuccess=zeros(1,3);
archiveSelections=0; fallbackEvals=0;

while fes < opts.MaxFEs
    generation = generation+1;
    fesAtStart = fes;
    [~,order] = sort(fit,'ascend');
    a = 2-2*min(fes/opts.MaxFEs,1);
    nextPop=pop; nextFit=fit;
    for i=1:n
        if fes>=opts.MaxFEs, break; end
        gateAttempts=gateAttempts+1;
        if useTournament
            guideIds = tournament_exemplars(fit,i,5,opts.TournamentSizes);
        else
            pool = [1:i-1, i+1:n];
            guideIds = pool(randperm(numel(pool),5));
        end
        [~,localOrder]=sort(fit(guideIds),'ascend');
        guideIds=guideIds(localOrder);
        % APLPSO only invokes pattern trials when all five sampled exemplars dominate Xi.
        if ~all(fit(guideIds)<fit(i)), continue; end
        gatePasses=gatePasses+1;

        % Prefix-coupled random coefficients make the 3/4/5 pattern comparison cleaner.
        sharedR1=rand(5,d); sharedR2=rand(5,d);
        fRatio=min(fes/opts.MaxFEs,1);
        c=[1, 1/(2-1)-fRatio/(2+1), 1/(3-1)-fRatio/(3+1), ...
            1/(4-1)-fRatio/(4+1), 1/(5-1)-fRatio/(5+1)];
        chosenX=pop(i,:); chosenFit=fit(i);
        archiveX=zeros(3,d); archiveFit=inf(3,1); improved=false;
        for modeIndex=1:3
            if fes>=opts.MaxFEs, break; end
            k=modeIndex+2;
            candidates=zeros(k,d);
            for j=1:k
                leader=pop(guideIds(j),:);
                A=2*a*sharedR1(j,:)-a;
                C=2*sharedR2(j,:);
                candidates(j,:)=leader-A.*abs(C.*leader-pop(i,:));
            end
            if useWeights
                weights=c(1:k);
                proposal=(weights*candidates)./sum(weights);
            else
                proposal=mean(candidates,1);
            end
            proposal=min(max(proposal,lb),ub);
            proposalFit=evaluate_one(objective,proposal);
            fes=fes+1;
            patternEvals(modeIndex)=patternEvals(modeIndex)+1;
            archiveX(modeIndex,:)=proposal;
            archiveFit(modeIndex)=proposalFit;
            if proposalFit<fit(i)
                chosenX=proposal; chosenFit=proposalFit; improved=true;
                patternSuccess(modeIndex)=patternSuccess(modeIndex)+1;
                break;
            end
        end
        if ~improved
            validArchive=isfinite(archiveFit);
            [chosenFit,archiveIdx]=min(archiveFit(validArchive));
            validRows=find(validArchive);
            chosenX=archiveX(validRows(archiveIdx),:);
            archiveSelections=archiveSelections+1;
        end
        nextPop(i,:)=chosenX; nextFit(i)=chosenFit;
    end

    % A collapsed/tied population can fail the all-five-dominators gate for every wolf.
    % Spend one ordinary GWO evaluation to guarantee forward FE progress.
    if fes==fesAtStart && fes<opts.MaxFEs
        [~,order]=sort(fit,'ascend');
        i=order(end);
        guideIds=order(1:3);
        candidate=zeros(3,d);
        for j=1:3
            leader=pop(guideIds(j),:);
            A=2*a*rand(1,d)-a; C=2*rand(1,d);
            candidate(j,:)=leader-A.*abs(C.*leader-pop(i,:));
        end
        proposal=min(max(mean(candidate,1),lb),ub);
        nextPop(i,:)=proposal;
        nextFit(i)=evaluate_one(objective,proposal);
        fes=fes+1; fallbackEvals=fallbackEvals+1;
    end
    pop=nextPop; fit=nextFit;
    [generationBest,generationI]=min(fit);
    if generationBest<bestFit
        bestFit=generationBest; bestX=pop(generationI,:);
    end
    traceFEs(end+1,1)=fes; %#ok<AGROW>
    traceBest(end+1,1)=bestFit; %#ok<AGROW>
    traceDiv(end+1,1)=population_diversity(pop,span); %#ok<AGROW>
end

result=struct('BestPosition',bestX,'BestFitness',bestFit,'FEs',fes, ...
    'Generations',generation,'Trace',struct('FEs',traceFEs, ...
    'BestFitness',traceBest,'Diversity',traceDiv),'Variant',variant, ...
    'Seed',opts.Seed,'Options',opts);
result.Diagnostics=struct('GateAttempts',gateAttempts,'GatePasses',gatePasses, ...
    'GatePassRate',gatePasses/max(gateAttempts,1),'PatternEvaluations',patternEvals, ...
    'PatternSuccesses',patternSuccess,'ArchiveSelections',archiveSelections, ...
    'ArchiveSelectionRate',archiveSelections/max(gatePasses,1), ...
    'FallbackEvaluations',fallbackEvals);
end

function opts=fill_defaults(opts)
defaults=struct('PopulationSize',30,'Seed',1,'TournamentSizes',[2 4], ...
    'Variant','apl_v2');
names=fieldnames(defaults);
for j=1:numel(names)
    if ~isfield(opts,names{j}) || isempty(opts.(names{j})), opts.(names{j})=defaults.(names{j}); end
end
if ~isfield(opts,'MaxFEs') || isempty(opts.MaxFEs) || ...
        opts.MaxFEs~=floor(opts.MaxFEs) || opts.MaxFEs<opts.PopulationSize
    error('gwo_optimize_apl:MaxFEs','MaxFEs must be an integer >= PopulationSize.');
end
if numel(opts.TournamentSizes)~=2 || any(opts.TournamentSizes<1) || ...
        any(opts.TournamentSizes~=floor(opts.TournamentSizes))
    error('gwo_optimize_apl:TournamentSizes','TournamentSizes must contain two positive integers.');
end
end

function value=evaluate_one(objective,x)
value=objective(x);
if ~isscalar(value) || ~isreal(value) || ~isfinite(value)
    error('gwo_optimize_apl:ObjectiveValue','Objective must return one finite real scalar.');
end
value=double(value);
end

function ids=tournament_exemplars(fit,current,k,tournamentSizes)
n=numel(fit); pool=[1:current-1,current+1:n]; ids=zeros(1,k);
for q=1:k
    available=pool(~ismember(pool,ids(1:max(q-1,0))));
    sizeNow=tournamentSizes(mod(q-1,numel(tournamentSizes))+1);
    sampled=available(randperm(numel(available),min(sizeNow,numel(available))));
    [~,win]=min(fit(sampled)); ids(q)=sampled(win);
end
end

function diversity=population_diversity(pop,span)
if size(pop,1)<2, diversity=0; return; end
normalized=pop./span;
total=0; count=0;
for i=1:size(pop,1)-1
    delta=normalized(i+1:end,:)-normalized(i,:);
    total=total+sum(sqrt(sum(delta.^2,2)));
    count=count+size(delta,1);
end
diversity=total/max(count,1);
end
