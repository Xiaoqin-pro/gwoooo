function verify_apl_handoff_modes()
%VERIFY_APL_HANDOFF_MODES Check FE accounting and archive/strict separation.
objective=@(x)sum(x.^2); lb=-5*ones(1,10); ub=5*ones(1,10);
for variant={'apl_handoff_archive','apl_handoff_strict'}
    opts=struct('PopulationSize',30,'MaxFEs',600,'Seed',41, ...
        'Variant',variant{1},'DLMFraction',0.2,'EliteCount',3, ...
        'LaplaceMu',0.6,'LaplaceSigma',0.3,'BDLFraction',0.5);
    out=gwo_optimize_apl_stage1(objective,lb,ub,opts); d=out.Diagnostics;
    assert(out.FEs==opts.MaxFEs,'Mode %s used %d/%d FEs.',variant{1},out.FEs,opts.MaxFEs);
    assert(isfinite(out.BestFitness),'Mode %s returned non-finite best.',variant{1});
    assert(d.DLMCount==d.HandoffTriggers,'Every handoff trigger must pay one initial DLM evaluation.');
    if strcmp(variant{1},'apl_handoff_strict')
        assert(d.ArchiveSelections==0,'Strict handoff must not select archive failures.');
    end
end
fprintf('APL handoff modes passed FE and acceptance checks.\n');
end
