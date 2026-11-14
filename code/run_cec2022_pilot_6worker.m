function results = run_cec2022_pilot_6worker()
%RUN_CEC2022_PILOT_6WORKER Small budget smoke pilot, not benchmark evidence.
codeRoot = fileparts(mfilename('fullpath'));
projectRoot = gwo_project_root();
benchmarkRoot = fullfile(projectRoot, 'data', 'CEC2022_reference');
outputDir = fullfile(projectRoot, 'results', 'pilot_6worker');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
addpath(codeRoot);
addpath(benchmarkRoot);
oldDir = pwd;
restoreClientDir = onCleanup(@() cd(oldDir)); %#ok<NASGU>
cd(benchmarkRoot);

pool = gcp('nocreate');
if isempty(pool)
    pool = parpool('local', 6);
elseif pool.NumWorkers ~= 6
    error('run_cec2022_pilot_6worker:PoolSize', ...
        'An existing pool has %d workers; expected 6.', pool.NumWorkers);
end
pctRunOnAll(sprintf('cd(''%s''); addpath(''%s''); addpath(''%s'');', ...
    benchmarkRoot, benchmarkRoot, codeRoot));

variants = {'gwo','tournament','adaptive','combined'};
seeds = 1:12;
nTasks = numel(variants) * numel(seeds);
rows = cell(nTasks, 8);
parfor q = 1:nTasks
    seedIndex = ceil(q / numel(variants));
    variantIndex = mod(q - 1, numel(variants)) + 1;
    seed = seeds(seedIndex);
    variant = variants{variantIndex};
    objective = @(x) cec2022_objective(x, 1);
    opts = struct('PopulationSize', 30, 'MaxFEs', 1000, ...
        'Seed', seed, 'Variant', variant, 'TournamentSizes', [2 4]);
    t = tic;
    result = gwo_optimize(objective, -100*ones(1,10), 100*ones(1,10), opts);
    rows(q,:) = {1, 10, seed, variant, result.BestFitness, ...
        result.FEs, result.Generations, toc(t)};
end
results = cell2table(rows, 'VariableNames', ...
    {'Function','Dimension','Seed','Variant','BestFitness','FEs','Generations','Seconds'});
results.Variant = string(results.Variant);
writetable(results, fullfile(outputDir, 'pilot_F01_D10_6worker.csv'));
save(fullfile(outputDir, 'pilot_F01_D10_6worker.mat'), 'results');
fprintf('Pilot complete: %d tasks, 6 workers, %d FEs/task. Pilot only.\n', nTasks, 1000);
end
