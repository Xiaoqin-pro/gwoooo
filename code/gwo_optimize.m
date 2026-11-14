function result = gwo_optimize(objective, lb, ub, opts)
%GWO_OPTIMIZE Budgeted GWO and adaptive-leader variants.
% objective: function handle taking one 1-by-D row vector and returning a scalar.
% Variants: 'gwo', 'tournament', 'adaptive', 'combined'.

if nargin < 4 || isempty(opts), opts = struct(); end
opts = apply_defaults(opts);
if ~isa(objective, 'function_handle')
    error('gwo_optimize:Objective', 'objective must be a function handle.');
end
lb = double(lb(:)');
ub = double(ub(:)');
if isempty(lb) || numel(lb) ~= numel(ub) || any(~isfinite(lb)) || ...
        any(~isfinite(ub)) || any(ub <= lb)
    error('gwo_optimize:Bounds', 'Bounds must be finite vectors with ub > lb.');
end
if opts.MaxFEs < opts.PopulationSize
    error('gwo_optimize:Budget', 'MaxFEs must be at least PopulationSize.');
end
variant = lower(char(opts.Variant));
if ~any(strcmp(variant, {'gwo','tournament','adaptive','combined'}))
    error('gwo_optimize:Variant', 'Unknown Variant: %s', variant);
end
if any(strcmp(variant, {'adaptive','combined'})) && opts.PopulationSize < 5
    error('gwo_optimize:PopulationSize', ...
        'Adaptive and combined variants require PopulationSize >= 5.');
end

rng(opts.Seed, 'twister');
n = opts.PopulationSize;
d = numel(lb);
span = ub - lb;
pop = lb + rand(n, d) .* span;
fit = inf(n, 1);
fes = 0;
for i = 1:n
    fit(i) = evaluate_one(objective, pop(i,:));
    fes = fes + 1;
end
[bestFit, bestIndex] = min(fit);
bestX = pop(bestIndex,:);
traceFEs = fes;
traceBest = bestFit;
generation = 0;

while fes < opts.MaxFEs
    generation = generation + 1;
    [~, order] = sort(fit, 'ascend');
    a = 2 - 2 * min(fes / opts.MaxFEs, 1);
    nextPop = pop;
    nextFit = fit;
    completedAny = false;

    for i = 1:n
        if fes >= opts.MaxFEs, break; end
        if strcmp(variant, 'gwo')
            guideOrder = order(1:min(3,n));
            candidate = gwo_proposal(pop(i,:), pop(guideOrder,:), a, lb, ub);
            nextPop(i,:) = candidate;
            nextFit(i) = evaluate_one(objective, candidate);
            fes = fes + 1;
        elseif strcmp(variant, 'tournament')
            guideOrder = select_guides(order, fit, i, 3, opts.TournamentSizes, true);
            candidate = gwo_proposal(pop(i,:), pop(guideOrder,:), a, lb, ub);
            nextPop(i,:) = candidate;
            nextFit(i) = evaluate_one(objective, candidate);
            fes = fes + 1;
        else
            useTournament = strcmp(variant, 'combined');
            guideOrder = select_guides(order, fit, i, 5, opts.TournamentSizes, useTournament);
            chosenX = pop(i,:);
            chosenFit = fit(i);
            bestProposalX = pop(i,:);
            bestProposalFit = inf;
            improved = false;
            sharedR1 = rand(5, d);
            sharedR2 = rand(5, d);
            patternCounts = 3:5;
            for k = patternCounts
                if fes >= opts.MaxFEs, break; end
                candidate = gwo_proposal(pop(i,:), pop(guideOrder(1:k),:), ...
                    a, lb, ub, sharedR1(1:k,:), sharedR2(1:k,:));
                candidateFit = evaluate_one(objective, candidate);
                fes = fes + 1;
                if candidateFit < bestProposalFit
                    bestProposalX = candidate;
                    bestProposalFit = candidateFit;
                end
                if candidateFit < fit(i)
                    chosenX = candidate;
                    chosenFit = candidateFit;
                    improved = true;
                    break;
                end
            end
            if ~improved && isfinite(bestProposalFit)
                chosenX = bestProposalX;
                chosenFit = bestProposalFit;
            end
            nextPop(i,:) = chosenX;
            nextFit(i) = chosenFit;
        end
        completedAny = true;
    end

    pop = nextPop;
    fit = nextFit;
    [genBest, genIndex] = min(fit);
    if genBest < bestFit
        bestFit = genBest;
        bestX = pop(genIndex,:);
    end
    traceFEs(end+1,1) = fes; %#ok<AGROW>
    traceBest(end+1,1) = bestFit; %#ok<AGROW>
    if ~completedAny, break; end
end

result = struct();
result.BestPosition = bestX;
result.BestFitness = bestFit;
result.FEs = fes;
result.Generations = generation;
result.Trace = struct('FEs', traceFEs, 'BestFitness', traceBest);
result.Variant = variant;
result.Seed = opts.Seed;
result.Options = opts;
end

function opts = apply_defaults(opts)
defaults = struct('PopulationSize', 30, 'Seed', 1, ...
    'Variant', 'gwo', 'TournamentSizes', [2 4]);
names = fieldnames(defaults);
for j = 1:numel(names)
    if ~isfield(opts, names{j}) || isempty(opts.(names{j}))
        opts.(names{j}) = defaults.(names{j});
    end
end
if opts.PopulationSize < 3 || opts.PopulationSize ~= floor(opts.PopulationSize)
    error('gwo_optimize:PopulationSize', 'PopulationSize must be an integer >= 3.');
end
if ~isfield(opts, 'MaxFEs') || isempty(opts.MaxFEs) || ...
        opts.MaxFEs ~= floor(opts.MaxFEs) || opts.MaxFEs < opts.PopulationSize
    error('gwo_optimize:MaxFEs', 'MaxFEs must be an integer >= PopulationSize.');
end
if numel(opts.TournamentSizes) ~= 2 || any(opts.TournamentSizes < 1) || ...
        any(opts.TournamentSizes ~= floor(opts.TournamentSizes))
    error('gwo_optimize:TournamentSizes', ...
        'TournamentSizes must contain two positive integers, e.g. [2 4].');
end
end

function y = evaluate_one(objective, x)
y = objective(x);
if ~isscalar(y) || ~isreal(y) || ~isfinite(y)
    error('gwo_optimize:ObjectiveValue', 'Objective must return one finite real scalar.');
end
y = double(y);
end

function xNew = gwo_proposal(x, guides, a, lb, ub, sharedR1, sharedR2)
k = size(guides, 1);
proposals = zeros(k, numel(x));
if nargin < 6
    sharedR1 = rand(k, numel(x));
    sharedR2 = rand(k, numel(x));
end
for j = 1:k
    A = 2 .* a .* sharedR1(j,:) - a;
    C = 2 .* sharedR2(j,:);
    D = abs(C .* guides(j,:) - x);
    proposals(j,:) = guides(j,:) - A .* D;
end
xNew = mean(proposals, 1);
xNew = min(max(xNew, lb), ub);
end

function guideOrder = select_guides(order, fit, currentIndex, k, tournamentSizes, useTournament)
n = numel(order);
selected = zeros(1, 0);
selected(end+1) = order(1);
if useTournament
    dominators = find(fit < fit(currentIndex));
    dominators(dominators == currentIndex) = [];
    for q = 1:k-1
        pool = dominators(~ismember(dominators, selected));
        if isempty(pool), break; end
        tournamentSize = tournamentSizes(mod(q-1, numel(tournamentSizes)) + 1);
        sampleCount = min(tournamentSize, numel(pool));
        candidates = pool(randperm(numel(pool), sampleCount));
        [~, localBest] = min(fit(candidates));
        selected(end+1) = candidates(localBest); %#ok<AGROW>
    end
end
for q = 1:n
    if numel(selected) >= k, break; end
    idx = order(q);
    if ~ismember(idx, selected)
        selected(end+1) = idx; %#ok<AGROW>
    end
end
guideOrder = selected(1:min(k, numel(selected)));
if numel(guideOrder) < 3
    error('gwo_optimize:GuideCount', 'At least three distinct guide wolves are required.');
end
end
