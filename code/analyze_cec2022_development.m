function report = analyze_cec2022_development(resultsCsv, outputDir)
%ANALYZE_CEC2022_DEVELOPMENT Summaries and paired development comparisons.
if nargin < 1 || isempty(resultsCsv)
    resultsCsv = fullfile(gwo_project_root(), 'results', ...
        'cec2022_6worker_dev', 'cec2022_development.csv');
end
if nargin < 2 || isempty(outputDir), outputDir = fileparts(resultsCsv); end
T = readtable(resultsCsv, 'TextType', 'string');
if any(T.Status ~= "OK")
    warning('analyze_cec2022_development:FailedRuns', ...
        '%d of %d rows have non-OK status.', sum(T.Status ~= "OK"), height(T));
end

optimum = [300 400 600 800 900 1800 2000 2200 2300 2400 2600 2700];
T.Error = max(T.BestFitness - optimum(T.Function)', 0);
variants = ["gwo" "tournament" "adaptive" "combined"];
funcs = unique(T.Function)';
dims = unique(T.Dimension)';
perFunction = table();
friedmanRows = cell(numel(funcs)*numel(dims), 5);
rankCounter = zeros(1, numel(variants));
winCounter = zeros(1, numel(variants));
problemCounter = 0;

for dim = dims
    for func = funcs
        problemCounter = problemCounter + 1;
        means = nan(1, numel(variants));
        medians = means;
        stds = means;
        sampleByVariant = cell(1, numel(variants));
        for v = 1:numel(variants)
            rows = T(T.Dimension == dim & T.Function == func & T.Variant == variants(v), :);
            [~, order] = sort(rows.Seed);
            rows = rows(order,:);
            e = rows.Error;
            sampleByVariant{v} = e;
            means(v) = mean(e);
            medians(v) = median(e);
            stds(v) = std(e);
        end
        ranks = tiedrank(means);
        rankCounter = rankCounter + ranks;
        winCounter = winCounter + (means == min(means));
        perFunction = [perFunction; table(func, dim, ...
            means(1), medians(1), stds(1), means(2), medians(2), stds(2), ...
            means(3), medians(3), stds(3), means(4), medians(4), stds(4), ...
            ranks(1), ranks(2), ranks(3), ranks(4), ...
            'VariableNames', {'Function','Dimension', ...
            'GWO_MeanError','GWO_MedianError','GWO_StdError', ...
            'Tournament_MeanError','Tournament_MedianError','Tournament_StdError', ...
            'Adaptive_MeanError','Adaptive_MedianError','Adaptive_StdError', ...
            'Combined_MeanError','Combined_MedianError','Combined_StdError', ...
            'GWO_Rank','Tournament_Rank','Adaptive_Rank','Combined_Rank'})]; %#ok<AGROW>

        seedCounts = cellfun(@numel, sampleByVariant);
        if numel(unique(seedCounts)) == 1 && seedCounts(1) >= 2
            X = zeros(seedCounts(1), numel(variants));
            for v = 1:numel(variants), X(:,v) = sampleByVariant{v}; end
            p = friedman(X, 1, 'off');
        else
            p = NaN;
        end
        friedmanRows(problemCounter,:) = {func, dim, p, min(means), variants(find(means == min(means),1))};
    end
end

contrasts = {"tournament","gwo"; "adaptive","gwo"; "combined","tournament"};
pairwise = table();
for c = 1:size(contrasts,1)
    method = contrasts{c,1}; comparator = contrasts{c,2};
    pValues = nan(height(perFunction),1);
    current = table();
    for i = 1:height(perFunction)
        f = perFunction.Function(i); d = perFunction.Dimension(i);
        a = T.Error(T.Function == f & T.Dimension == d & T.Variant == method);
        b = T.Error(T.Function == f & T.Dimension == d & T.Variant == comparator);
        seedsA = T.Seed(T.Function == f & T.Dimension == d & T.Variant == method);
        seedsB = T.Seed(T.Function == f & T.Dimension == d & T.Variant == comparator);
        [seedsA, ia] = sort(seedsA); [seedsB, ib] = sort(seedsB);
        a = a(ia); b = b(ib);
        if isequal(seedsA, seedsB) && numel(a) >= 2
            pValues(i) = signrank(a, b);
            wins = sum(a < b); losses = sum(a > b); ties = sum(a == b);
            delta = median(a - b);
        else
            wins = NaN; losses = NaN; ties = NaN; delta = NaN;
        end
        current = [current; table(f, d, string(method), string(comparator), ...
            wins, losses, ties, delta, pValues(i), ...
            'VariableNames', {'Function','Dimension','Method','Comparator', ...
            'Wins','Losses','Ties','MedianErrorDifference','RawP'})]; %#ok<AGROW>
    end
    current.HolmP = holm_adjust(pValues);
    pairwise = [pairwise; current]; %#ok<AGROW>
end

overall = table(variants', rankCounter' ./ problemCounter, winCounter', ...
    'VariableNames', {'Variant','AverageFunctionRank','BestMeanErrorCases'});
friedmanSummary = cell2table(friedmanRows, 'VariableNames', ...
    {'Function','Dimension','FriedmanP','BestMeanError','BestVariant'});
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
writetable(perFunction, fullfile(outputDir, 'cec2022_per_function_summary.csv'));
writetable(overall, fullfile(outputDir, 'cec2022_algorithm_summary.csv'));
writetable(pairwise, fullfile(outputDir, 'cec2022_pairwise_wilcoxon_holm.csv'));
writetable(friedmanSummary, fullfile(outputDir, 'cec2022_friedman_by_function.csv'));
report = struct('PerFunction', perFunction, 'Overall', overall, ...
    'Pairwise', pairwise, 'FriedmanByFunction', friedmanSummary);
end

function adjusted = holm_adjust(p)
adjusted = nan(size(p));
valid = find(isfinite(p));
if isempty(valid), return; end
[sortedP, order] = sort(p(valid));
m = numel(sortedP);
stepDown = cummax((m - (1:m)' + 1) .* sortedP);
stepDown = min(stepDown, 1);
adjusted(valid(order)) = stepDown;
end
