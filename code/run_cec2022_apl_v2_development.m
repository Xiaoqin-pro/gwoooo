function results = run_cec2022_apl_v2_development()
%RUN_CEC2022_APL_V2_DEVELOPMENT Six-version APL migration screening.
% Uses fresh development seeds 41:50 and a local six-worker pool.
projectRoot = gwo_project_root();
outputDir = fullfile(projectRoot,'results','cec2022_apl_v2_6worker_dev');
variants = {'gwo','tournament','apl_v2','apl_weighted', ...
    'tournament_apl_v2','tournament_apl_weighted'};
results = run_cec2022_development(outputDir,41:50,6,1:12,[10 20],variants);
end
