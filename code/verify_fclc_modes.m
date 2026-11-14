function verify_fclc_modes()
%VERIFY_FCLC_MODES Verify FE counts and probe accounting for all FCLC modes.
objective=@(x)sum(x.^2);
lb=-5*ones(1,10); ub=5*ones(1,10);
modes={'static','gclc','fclc'};
for k=1:numel(modes)
    opts=struct('PopulationSize',30,'MaxFEs',300,'Seed',41,'Mode',modes{k});
    out=gwo_optimize_fclc(objective,lb,ub,opts);
    assert(out.FEs==opts.MaxFEs,'Mode %s used %d/%d FEs.',modes{k},out.FEs,opts.MaxFEs);
    assert(isfinite(out.BestFitness),'Mode %s returned non-finite best.',modes{k});
    assert(out.BestFitness<=out.BestPropagatedFitness, ...
        'Best evaluated result should include all propagated candidates.');
    if strcmp(modes{k},'static')
        assert(out.Diagnostics.ProbeCount==0,'Static weighted mode must not probe.');
    else
        assert(out.Diagnostics.ProbeCount>0,'Mode %s did not perform probes.',modes{k});
    end
end
fprintf('FCLC modes passed FE and probe-accounting checks.\n');
end
