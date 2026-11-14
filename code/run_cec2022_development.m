function results = run_cec2022_development(outputDir, seeds, workerCount, functionIds, dims, variants)
%RUN_CEC2022_DEVELOPMENT CEC2022 screening using a MATLAB parallel pool.
% Defaults: 4 variants x 12 functions x D=[10,20] x 10 development seeds.
% Official MaxFES: 200000 at D=10, 1000000 at D=20.

codeRoot = fileparts(mfilename('fullpath'));
projectRoot = gwo_project_root();
benchmarkRoot = fullfile(projectRoot, 'data', 'CEC2022_reference');
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(projectRoot, 'results', 'cec2022_6worker_dev');
end
if nargin < 2 || isempty(seeds), seeds = 1:10; end
if nargin < 3 || isempty(workerCount), workerCount = 6; end
if nargin < 4 || isempty(functionIds), functionIds = 1:12; end
if nargin < 5 || isempty(dims), dims = [10 20]; end
if nargin < 6 || isempty(variants)
    variants = {'gwo','tournament','adaptive','combined'};
end
if ~exist(fullfile(benchmarkRoot, 'cec22_test_func.mexw64'), 'file')
    error('run_cec2022_development:MissingMEX', ...
        'The bundled cec22_test_func.mexw64 was not found in %s.', benchmarkRoot);
end
if ~exist(fullfile(benchmarkRoot, 'input_data'), 'dir')
    error('run_cec2022_development:MissingData', ...
        'CEC2022 input_data directory is missing from %s.', benchmarkRoot);
end
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
addpath(codeRoot);
addpath(benchmarkRoot);

pool = gcp('nocreate');
if isempty(pool)
    pool = parpool('local', workerCount);
elseif pool.NumWorkers ~= workerCount
    error('run_cec2022_development:PoolSize', ...
        'An existing pool has %d workers; close it or rerun with that worker count.', ...
        pool.NumWorkers);
end

% CEC MEX reads input_data relative to each MATLAB process working directory.
oldDir = pwd;
restoreClientDir = onCleanup(@() cd(oldDir)); %#ok<NASGU>
cd(benchmarkRoot);
workerSetup = sprintf('cd(''%s''); addpath(''%s''); addpath(''%s'');', ...
    benchmarkRoot, benchmarkRoot, codeRoot);
pctRunOnAll(workerSetup);

csvPath = fullfile(outputDir, 'cec2022_development.csv');
matPath = fullfile(outputDir, 'cec2022_development.mat');
results = table();

for dIndex = 1:numel(dims)
    dim = dims(dIndex);
    if dim == 10, maxFEs = 200000; else, maxFEs = 1000000; end
    lb = -100 * ones(1, dim);
    ub = 100 * ones(1, dim);
    for functionId = functionIds
        nRuns = numel(seeds) * numel(variants);
        records = cell(nRuns, 25);
        parfor q = 1:nRuns
            seedIndex = ceil(q / numel(variants));
            variantIndex = mod(q - 1, numel(variants)) + 1;
            runSeed = seeds(seedIndex);
            variant = variants{variantIndex};
            runKey = sprintf('F%02d_D%02d_S%04d_%s', functionId, dim, runSeed, variant);
            tRun = tic;
            try
                objective = @(x) cec2022_objective(x, functionId);
                opts = struct('PopulationSize', 30, 'MaxFEs', maxFEs, ...
                    'Seed', runSeed, 'Variant', variant, 'TournamentSizes', [2 4]);
                if contains(variant,'apl')
                    result = gwo_optimize_apl(objective, lb, ub, opts);
                else
                    result = gwo_optimize_instrumented(objective, lb, ub, opts);
                end
                diagValues = nan(1,12);
                if isfield(result,'Diagnostics')
                    dg=result.Diagnostics;
                    diagValues=[dg.GateAttempts,dg.GatePasses,dg.GatePassRate, ...
                        dg.PatternEvaluations,dg.PatternSuccesses,dg.ArchiveSelections, ...
                        dg.ArchiveSelectionRate,dg.FallbackEvaluations];
                end
                diversityInitial=result.Trace.Diversity(1);
                diversityFinal=result.Trace.Diversity(end);
                diversityMin=min(result.Trace.Diversity);
                records(q,:) = [{functionId, dim, runSeed, variant, ...
                    result.BestFitness, result.FEs, result.Generations, ...
                    toc(tRun), 'OK', runKey}, num2cell(diagValues), ...
                    {diversityInitial,diversityFinal,diversityMin}];
            catch ME
                records(q,:) = [{functionId, dim, runSeed, variant, ...
                    NaN, NaN, NaN, toc(tRun), ME.message, runKey}, ...
                    num2cell(nan(1,12)), {NaN,NaN,NaN}];
            end
        end
        block = cell2table(records, 'VariableNames', ...
            {'Function','Dimension','Seed','Variant','BestFitness','FEs', ...
            'Generations','Seconds','Status','RunKey','GateAttempts','GatePasses', ...
            'GatePassRate','Pattern3Evaluations','Pattern4Evaluations', ...
            'Pattern5Evaluations','Pattern3Successes','Pattern4Successes', ...
            'Pattern5Successes','ArchiveSelections','ArchiveSelectionRate', ...
            'FallbackEvaluations','DiversityInitial','DiversityFinal','DiversityMin'});
        block.Variant = string(block.Variant);
        block.Status = string(block.Status);
        block.RunKey = string(block.RunKey);
        if isempty(results), results = block; else, results = [results; block]; end %#ok<AGROW>
        writetable(results, csvPath);
        save(matPath, 'results', 'seeds', 'workerCount', 'variants', 'dims');
        fprintf('Checkpoint: F%d, D=%d complete (%d/%d runs; %d workers).\n', ...
            functionId, dim, height(results), numel(functionIds)*numel(dims)*numel(seeds)*numel(variants), workerCount);
    end
end
end
