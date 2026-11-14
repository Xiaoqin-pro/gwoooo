function merged=run_fclc_stage1_smoke()
%RUN_FCLC_STAGE1_SMOKE Small real-objective path check; separate from results.
root=gwo_project_root();
outputDir=fullfile(root,'results','fclc_stage1_smoke');
merged=run_fclc_stage1_dev(outputDir,41,6,"SPHERE",300, ...
    ["GWO","WGWO_STATIC","GCLC","FCLC"]);
end
