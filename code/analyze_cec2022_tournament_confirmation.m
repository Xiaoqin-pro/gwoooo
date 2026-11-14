function report = analyze_cec2022_tournament_confirmation(resultsCsv, outputDir)
% Paired 30-seed confirmation summary for GWO vs tournament-guided GWO.
if nargin < 1 || isempty(resultsCsv)
    resultsCsv = fullfile(gwo_project_root(), 'results', ...
        'cec2022_tournament_confirmation_6worker', 'cec2022_development.csv');
end
if nargin < 2 || isempty(outputDir), outputDir = fileparts(resultsCsv); end
T = readtable(resultsCsv, 'TextType', 'string');
optimum = [300 400 600 800 900 1800 2000 2200 2300 2400 2600 2700];
T.Error = max(T.BestFitness - optimum(T.Function)', 0);
funcs = unique(T.Function)';
dims = unique(T.Dimension)';
summary = table();
p = nan(numel(funcs)*numel(dims),1);
idx = 0;
for dim = dims
    for func = funcs
        idx = idx + 1;
        baseline = T(T.Function==func & T.Dimension==dim & T.Variant=="gwo",:);
        method = T(T.Function==func & T.Dimension==dim & T.Variant=="tournament",:);
        [~,ia] = sort(baseline.Seed); [~,ib] = sort(method.Seed);
        baseline = baseline(ia,:); method = method(ib,:);
        if ~isequal(baseline.Seed, method.Seed)
            error('analyze_cec2022_tournament_confirmation:Seeds', ...
                'GWO and tournament seed sets do not match for F%d D=%d.', func, dim);
        end
        a = baseline.Error; b = method.Error;
        p(idx) = signrank(b,a);
        summary = [summary; table(func,dim,numel(a),mean(a),median(a),std(a), ...
            mean(b),median(b),std(b),sum(b<a),sum(b>a),sum(b==a),median(b-a),p(idx), ...
            'VariableNames', {'Function','Dimension','NSeeds', ...
            'GWO_MeanError','GWO_MedianError','GWO_StdError', ...
            'Tournament_MeanError','Tournament_MedianError','Tournament_StdError', ...
            'TournamentWins','TournamentLosses','Ties','MedianErrorDifference','RawP'})]; %#ok<AGROW>
    end
end
summary.HolmP = holm_adjust(p);
if ~exist(outputDir,'dir'), mkdir(outputDir); end
writetable(summary, fullfile(outputDir,'cec2022_tournament_confirmation_summary.csv'));
report = summary;
end

function adjusted = holm_adjust(p)
adjusted = nan(size(p));
valid = find(isfinite(p));
if isempty(valid), return; end
[sortedP,order] = sort(p(valid));
m = numel(sortedP);
stepDown = min(cummax((m-(1:m)'+1).*sortedP),1);
adjusted(valid(order)) = stepDown;
end
