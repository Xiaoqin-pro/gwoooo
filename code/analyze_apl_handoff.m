function report=analyze_apl_handoff(mergedCsv,outputDir)
%ANALYZE_APL_HANDOFF Analyze A0/A2/A7 reused rows and new A8/A9 variants.
root=gwo_project_root();
if nargin<1 || isempty(mergedCsv)
    mergedCsv=fullfile(root,'results','apl_handoff_6worker_dev','A0_A2_A7_A8_A9_merged.csv');
end
if nargin<2 || isempty(outputDir), outputDir=fileparts(mergedCsv); end
T=readtable(mergedCsv,'TextType','string');
variants=["A0_APLweighted","A2_DLM2","A7_DLM2_BDL50", ...
    "A8_APL_HandoffArchive","A9_APL_HandoffStrict"];
funcs=unique(T.Function)'; dims=unique(T.Dimension)';
optimum=[300 400 600 800 900 1800 2000 2200 2300 2400 2600 2700];
T.Error=nan(height(T),1);
for k=1:height(T)
    T.Error(k)=max(T.BestFitness(k)-optimum(T.Function(k)),0);
end
perRows=cell(numel(funcs)*numel(dims),2+4*numel(variants));
rankSum=zeros(numel(variants),1); bestCount=zeros(numel(variants),1); q=0;
for d=dims
    for f=funcs
        q=q+1; means=nan(1,numel(variants)); meds=means; sds=means;
        for a=1:numel(variants)
            rows=sortrows(T(T.Function==f & T.Dimension==d & T.Algorithm==variants(a),:),'Seed');
            if height(rows)~=10 || any(rows.Status~="OK")
                error('Incomplete data for %s F%d D%d.',variants(a),f,d);
            end
            if any(rows.FEs~=rows.MaxFEs), error('FE mismatch for %s F%d D%d.',variants(a),f,d); end
            means(a)=mean(rows.Error); meds(a)=median(rows.Error); sds(a)=std(rows.Error);
        end
        rr=tiedrank(means); rankSum=rankSum+rr'; bestCount=bestCount+(means==min(means))';
        row={f,d};
        for a=1:numel(variants), row=[row,{means(a),meds(a),sds(a),rr(a)}]; end %#ok<AGROW>
        perRows(q,:)=row;
    end
end
names={'Function','Dimension'};
for a=1:numel(variants)
    tag=char(variants(a)); names=[names,{[tag '_MeanError'],[tag '_MedianError'], ...
        [tag '_StdError'],[tag '_Rank']}]; %#ok<AGROW>
end
perFunction=cell2table(perRows,'VariableNames',names);
overall=table(variants',rankSum/(numel(funcs)*numel(dims)),bestCount, ...
    'VariableNames',{'Algorithm','AverageFunctionRank','BestMeanErrorCases'});

methods=["A8_APL_HandoffArchive","A9_APL_HandoffStrict"];
comparators=["A0_APLweighted","A2_DLM2","A7_DLM2_BDL50", ...
    "A8_APL_HandoffArchive","A9_APL_HandoffStrict"];
pairs=cell(0,10);
for m=methods
    for c=comparators
        if (m=="A8_APL_HandoffArchive" && c==m) || ...
                (m=="A9_APL_HandoffStrict" && c==m), continue; end
        for f=funcs
            for d=dims
                a=T.Error(T.Function==f & T.Dimension==d & T.Algorithm==m);
                b=T.Error(T.Function==f & T.Dimension==d & T.Algorithm==c);
                sa=T.Seed(T.Function==f & T.Dimension==d & T.Algorithm==m);
                sb=T.Seed(T.Function==f & T.Dimension==d & T.Algorithm==c);
                [sa,ia]=sort(sa); [sb,ib]=sort(sb); a=a(ia); b=b(ib);
                if ~isequal(sa,sb), error('Seed mismatch for %s vs %s.',m,c); end
                diff=a-b; u=unique([a(:);b(:)]);
                if isscalar(u), p=1; else, p=ranksum(a,b); end
                rel=100*(mean(b)-mean(a))/max(abs(mean(b)),1e-12);
                pairs(end+1,:)={f,d,char(m),char(c),numel(a),sum(diff<0), ...
                    sum(diff>0),median(diff),rel,p}; %#ok<AGROW>
            end
        end
    end
end
pairwise=cell2table(pairs,'VariableNames',{'Function','Dimension','Method','Comparator', ...
    'NSeeds','MethodWins','MethodLosses','MedianErrorDifference', ...
    'MeanRelativeImprovementPct','RankSumP_Unadjusted'});
pairwise.Method=string(pairwise.Method); pairwise.Comparator=string(pairwise.Comparator);

raw=readtable(fullfile(outputDir,'A8_A9_new_runs.csv'),'TextType','string');
diagnostics=groupsummary(raw,{'Algorithm'},'mean',{'APLGatePassRate','ArchiveSelections', ...
    'BDLMeanK','DLMCount','DLMSuccess','DoubleDLMCount','DoubleDLMSuccess', ...
    'HandoffOpportunities','HandoffTriggers','StrictRetains','Seconds'});
diagnostics.HandoffRate=diagnostics.mean_HandoffTriggers./max(diagnostics.mean_HandoffOpportunities,1);

trace=readtable(fullfile(outputDir,'A8_A9_diversity_trace_1pct.csv'),'TextType','string');
traceRows=cell(2*numel(funcs)*numel(dims)*100,7); q=0;
handoffAlgs=["A8_APL_HandoffArchive","A9_APL_HandoffStrict"];
for a=handoffAlgs
    for f=funcs
        for d=dims
            rows=trace(trace.Algorithm==a & trace.Function==f & trace.Dimension==d,:);
            if height(rows)~=10, error('Incomplete diversity trace for %s F%d D%d.',a,f,d); end
            for pct=1:100
                col=sprintf('FEpct_%02d',pct); vals=rows.(col);
                q=q+1; traceRows(q,:)={char(a),f,d,pct,mean(vals),std(vals),numel(vals)};
            end
        end
    end
end
meanDiversity=cell2table(traceRows,'VariableNames', ...
    {'Algorithm','Function','Dimension','FEPercent','MeanDiversity','StdDiversity','NSeeds'});
meanDiversity.Algorithm=string(meanDiversity.Algorithm);

writetable(perFunction,fullfile(outputDir,'APL_handoff_per_function.csv'));
writetable(overall,fullfile(outputDir,'APL_handoff_algorithm_summary.csv'));
writetable(pairwise,fullfile(outputDir,'APL_handoff_ranksum.csv'));
writetable(diagnostics,fullfile(outputDir,'APL_handoff_diagnostics.csv'));
writetable(meanDiversity,fullfile(outputDir,'APL_handoff_mean_diversity.csv'));
write_report(fullfile(outputDir,'APL_HANDOFF_REPORT.md'),overall,pairwise,diagnostics,raw,T);
report=struct('PerFunction',perFunction,'Overall',overall,'Pairwise',pairwise, ...
    'Diagnostics',diagnostics,'Diversity',meanDiversity,'NewRows',height(raw),'MergedRows',height(T));
end

function write_report(path,overall,pairwise,diagnostics,raw,T)
fid=fopen(path,'w');
if fid<0, error('Could not open APL handoff report.'); end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
methods=["A8_APL_HandoffArchive","A9_APL_HandoffStrict"];
variants=["A0_APLweighted","A2_DLM2","A7_DLM2_BDL50", ...
    "A8_APL_HandoffArchive","A9_APL_HandoffStrict"];
comparators=["A0_APLweighted","A2_DLM2","A7_DLM2_BDL50", ...
    "A8_APL_HandoffArchive","A9_APL_HandoffStrict"];
fprintf(fid,'# APL Conditional Recovery Screen\n\n');
fprintf(fid,'**Protocol:** CEC2022 F1–F12, D=10/20, N=30, seeds 41–50, six MATLAB workers; MaxFEs=200,000 at D=10 and 1,000,000 at D=20.\n\n');
fprintf(fid,'**New runs:** %d A8/A9 rows, %d OK, %d non-OK; 720 matching A0/A2/A7 rows reused. Merged rows: %d. All rows used fixed MaxFEs.\n\n', ...
    height(raw),sum(raw.Status=="OK"),sum(raw.Status~="OK"),height(T));
fprintf(fid,'A8 runs weighted APL patterns first, then applies masked DLM-2 only to selected worst-20%% non-elites whose APL step did not improve. A9 uses the same handoff but retains the old position instead of accepting the non-improving APL archive.\n\n');
fprintf(fid,'## Average ranks\n\nLower is better; ranks average across 24 function/dimension settings. Best-mean counts include ties.\n\n| Algorithm | Average rank | Best/tied-best settings |\n|---|---:|---:|\n');
overall=sortrows(overall,'AverageFunctionRank');
for i=1:height(overall)
    fprintf(fid,'| %s | %.3f | %d/24 |\n',char(overall.Algorithm(i)), ...
        overall.AverageFunctionRank(i),overall.BestMeanErrorCases(i));
end
fprintf(fid,'\n## Average ranks by dimension\n\nRanks are first computed from the 12 function-wise 10-seed mean errors within each dimension, then averaged.\n\n| Dimension | A0 APL-weighted | A2 DLM-2 | A7 DLM-2+BDL50 | A8 archive | A9 strict |\n|---:|---:|---:|---:|---:|---:|\n');
dims=unique(T.Dimension)'; funcs=unique(T.Function)';
for d=dims
    rankTotals=zeros(1,numel(variants));
    for f=funcs
        means=nan(1,numel(variants));
        for a=1:numel(variants)
            vals=T.Error(T.Function==f & T.Dimension==d & T.Algorithm==variants(a));
            means(a)=mean(vals);
        end
        rankTotals=rankTotals+tiedrank(means);
    end
    avgRanks=rankTotals/numel(funcs);
    fprintf(fid,'| %d | %.3f | %.3f | %.3f | %.3f | %.3f |\n', ...
        d,avgRanks(1),avgRanks(2),avgRanks(3),avgRanks(4),avgRanks(5));
end
fprintf(fid,'\n## Pairwise tests\n\nUnadjusted two-sided Wilcoxon rank-sum tests are reported per setting without Holm correction, following the project screen preference. Seed IDs match, but the test is unpaired. Direction among significant settings is based on the difference in mean residual error.\n\n| Method | Comparator | Significant p<.05 | Favor method / comparator | Seed wins / losses |\n|---|---|---:|---:|---:|\n');
for m=methods
    for c=comparators
        if (m=="A8_APL_HandoffArchive" && c==m) || ...
                (m=="A9_APL_HandoffStrict" && c==m), continue; end
        r=pairwise(pairwise.Method==m & pairwise.Comparator==c,:);
        sig=r(r.RankSumP_Unadjusted<0.05,:);
        favorMethod=sum(sig.MeanRelativeImprovementPct>0);
        favorComparator=sum(sig.MeanRelativeImprovementPct<0);
        fprintf(fid,'| %s | %s | %d/24 | %d / %d | %d / %d |\n', ...
            char(m),char(c),height(sig),favorMethod,favorComparator, ...
            sum(r.MethodWins),sum(r.MethodLosses));
    end
end
fprintf(fid,'\n## Diagnostics\n\n| Variant | Gate pass | Archive selections | Handoff opportunities | Handoff triggers | Strict retains | Mean DLM successes |\n|---|---:|---:|---:|---:|---:|---:|\n');
for i=1:height(diagnostics)
    fprintf(fid,'| %s | %.3f | %.1f | %.1f | %.1f | %.1f | %.1f |\n', ...
        char(diagnostics.Algorithm(i)),diagnostics.mean_APLGatePassRate(i), ...
        diagnostics.mean_ArchiveSelections(i),diagnostics.mean_HandoffOpportunities(i), ...
        diagnostics.mean_HandoffTriggers(i),diagnostics.mean_StrictRetains(i), ...
        diagnostics.mean_DLMSuccess(i));
end
fprintf(fid,'\n## Interpretation\n\nA9 ranks first overall and at D=10, while A7 has a better average rank than A9 at D=20. The total ranking therefore hides a dimension-dependent result. A9 keeps the original wolf after all APL patterns fail; A8 instead selects the best evaluated APL candidate, which can still be worse than the original wolf, before any eligible DLM recovery. This screen is consistent with preserving the incumbent before recovery, but does not establish why the difference occurs.\n\nDLM success counts are not directly comparable between A8 and A9: A8 tests improvement relative to its archived candidate, while A9 tests relative to the retained incumbent. The screen reuses matching seed IDs and is not independent confirmation. Per-seed raw rows are in `A8_A9_new_runs.csv` and `A0_A2_A7_A8_A9_merged.csv`; per-function summaries, diversity traces, and diagnostics are stored beside this report. These development results do not establish broad novelty or paper readiness.\n');
end
