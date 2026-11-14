%RUN_DEMO Small synthetic-objective entry point for a MATLAB smoke run.
% This is interface validation only, not CEC evidence.
clear; clc;
addpath(fileparts(mfilename('fullpath')));
objective = @(x) sum(x.^2);
variants = {'gwo','tournament','adaptive','combined'};
opts = struct('PopulationSize', 20, 'MaxFEs', 500, 'Seed', 11, ...
    'TournamentSizes', [2 4]);
lb = -100 * ones(1, 10);
ub = 100 * ones(1, 10);
for i = 1:numel(variants)
    opts.Variant = variants{i};
    result = gwo_optimize(objective, lb, ub, opts);
    fprintf('%-12s f=%g, FEs=%d, generations=%d\n', result.Variant, ...
        result.BestFitness, result.FEs, result.Generations);
end
