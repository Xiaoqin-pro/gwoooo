function results = run_cec2022_tournament_confirmation()
%RUN_CEC2022_TOURNAMENT_CONFIRMATION Fresh-seed paired GWO vs tournament run.
projectRoot = gwo_project_root();
outputDir = fullfile(projectRoot, 'results', 'cec2022_tournament_confirmation_6worker');
results = run_cec2022_development(outputDir, 11:40, 6, 1:12, [10 20], ...
    {'gwo','tournament'});
end
