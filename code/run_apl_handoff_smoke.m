function T=run_apl_handoff_smoke()
%RUN_APL_HANDOFF_SMOKE Small Sphere path check; not benchmark evidence.
root=gwo_project_root(); outDir=fullfile(root,'results','apl_handoff_smoke');
if ~isfolder(outDir), mkdir(outDir); end
objective=@(x)sum(x.^2); lb=-5*ones(1,10); ub=5*ones(1,10);
variants={'apl_handoff_archive','apl_handoff_strict'};
rows=cell(2,8);
for k=1:2
    opts=struct('PopulationSize',30,'MaxFEs',600,'Seed',41, ...
        'Variant',variants{k},'DLMFraction',0.2,'EliteCount',3, ...
        'LaplaceMu',0.6,'LaplaceSigma',0.3,'BDLFraction',0.5);
    out=gwo_optimize_apl_stage1(objective,lb,ub,opts); d=out.Diagnostics;
    rows(k,:)={variants{k},41,out.BestFitness,out.FEs,d.APLGatePassRate, ...
        d.HandoffOpportunities,d.HandoffTriggers,d.StrictRetains};
end
T=cell2table(rows,'VariableNames',{'Variant','Seed','BestFitness','FEs', ...
    'APLGatePassRate','HandoffOpportunities','HandoffTriggers','StrictRetains'});
T.Variant=string(T.Variant); writetable(T,fullfile(outDir,'APL_handoff_smoke.csv'));
fprintf('APL handoff smoke complete: %d/%d modes, FE cap 600.\n',sum(T.FEs==600),height(T));
end
