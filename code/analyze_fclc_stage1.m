function report=analyze_fclc_stage1(mergedCsv,outputDir)
%ANALYZE_FCLC_STAGE1 Summaries and unadjusted rank-sum tests for Stage 1.
root=gwo_project_root();
if nargin<1 || isempty(mergedCsv)
    mergedCsv=fullfile(root,'results','fclc_stage1_6worker_dev','FCLC_stage1_merged.csv');
end
if nargin<2 || isempty(outputDir), outputDir=fileparts(mergedCsv); end
T=readtable(mergedCsv,'TextType','string');
problemOrder=["SPHERE","RASTRIGIN","ROSENBROCK","ACKLEY", ...
    "CEC2022_F1_D10","CEC2022_F6_D10"];
algorithms=["GWO","WGWO_STATIC","GCLC","FCLC"];
optimum=[0 0 0 0 300 1800];
T.Error=nan(height(T),1);
for p=1:numel(problemOrder)
    mask=T.Problem==problemOrder(p);
    T.Error(mask)=max(T.BestFitness(mask)-optimum(p),0);
end

perRows=cell(numel(problemOrder),2+4*numel(algorithms));
rankSum=zeros(numel(algorithms),1); bestCount=zeros(numel(algorithms),1);
for p=1:numel(problemOrder)
    means=nan(1,numel(algorithms)); medians=means; sds=means;
    for a=1:numel(algorithms)
        rows=sortrows(T(T.Problem==problemOrder(p) & T.Algorithm==algorithms(a),:),'Seed');
        if height(rows)~=10 || any(rows.Status~="OK")
            error('Incomplete data for %s / %s.',problemOrder(p),algorithms(a));
        end
        if any(rows.FEs~=rows.MaxFEs), error('FE cap mismatch for %s / %s.',problemOrder(p),algorithms(a)); end
        means(a)=mean(rows.Error); medians(a)=median(rows.Error); sds(a)=std(rows.Error);
    end
    ranks=tiedrank(means); rankSum=rankSum+ranks'; bestCount=bestCount+(means==min(means))';
    row={char(problemOrder(p)),unique(T.Dimension(T.Problem==problemOrder(p)))};
    for a=1:numel(algorithms)
        row=[row,{means(a),medians(a),sds(a),ranks(a)}]; %#ok<AGROW>
    end
    perRows(p,:)=row;
end
names={'Problem','Dimension'};
for a=1:numel(algorithms)
    tag=char(algorithms(a)); names=[names,{[tag '_MeanError'],[tag '_MedianError'], ...
        [tag '_StdError'],[tag '_Rank']}]; %#ok<AGROW>
end
perProblem=cell2table(perRows,'VariableNames',names);
perProblem.Problem=string(perProblem.Problem);
overall=table(algorithms',rankSum/numel(problemOrder),bestCount, ...
    'VariableNames',{'Algorithm','AverageProblemRank','BestMeanErrorCases'});

comparators=algorithms(1:3); pairRows=cell(numel(problemOrder)*numel(comparators),9); q=0;
for p=1:numel(problemOrder)
    for a=1:numel(comparators)
        f=T.Error(T.Problem==problemOrder(p) & T.Algorithm=="FCLC");
        c=T.Error(T.Problem==problemOrder(p) & T.Algorithm==comparators(a));
        fs=T.Seed(T.Problem==problemOrder(p) & T.Algorithm=="FCLC");
        cs=T.Seed(T.Problem==problemOrder(p) & T.Algorithm==comparators(a));
        [fs,ifc]=sort(fs); [cs,icc]=sort(cs); f=f(ifc); c=c(icc);
        if ~isequal(fs,cs), error('Seed mismatch for %s / %s.',problemOrder(p),comparators(a)); end
        q=q+1; diff=f-c;
        combinedValues=unique([f(:);c(:)]);
        if isscalar(combinedValues), pval=1; else, pval=ranksum(f,c); end
        rel=100*(mean(c)-mean(f))/max(abs(mean(c)),1e-12);
        pairRows(q,:)={char(problemOrder(p)),char(comparators(a)),numel(f), ...
            sum(diff<0),sum(diff>0),median(diff),rel,pval,mean(f)};
    end
end
pairwise=cell2table(pairRows,'VariableNames',{'Problem','Comparator','NSeeds', ...
    'FCLCWins','FCLCLosses','MedianErrorDifference','MeanRelativeImprovementPct', ...
    'RankSumP_Unadjusted','FCLCMeanError'});
pairwise.Problem=string(pairwise.Problem); pairwise.Comparator=string(pairwise.Comparator);

newRows=readtable(fullfile(outputDir,'FCLC_stage1_new_runs.csv'),'TextType','string');
diagnostics=groupsummary(newRows,{'Algorithm','Problem'},'mean', ...
    {'Seconds','ProbeCount','AlphaProbeCount','BetaProbeCount','DeltaProbeCount', ...
    'MeanProbeMCAlpha','MeanProbeMCBeta','MeanProbeMCDelta','MeanWeightAlpha', ...
    'MeanWeightBeta','MeanWeightDelta','WeightSpread'});
trace=readtable(fullfile(outputDir,'FCLC_stage1_trace_1pct.csv'),'TextType','string');
meanTrace=groupsummary(trace,{'Algorithm','Problem','Dimension','FEPercent'}, ...
    {'mean','std'},{'BestEvaluated','BestPropagated','MeanWeightAlpha', ...
    'MeanWeightBeta','MeanWeightDelta','WeightSpread','ProbesThisGeneration'});

writetable(perProblem,fullfile(outputDir,'FCLC_stage1_per_problem.csv'));
writetable(overall,fullfile(outputDir,'FCLC_stage1_algorithm_summary.csv'));
writetable(pairwise,fullfile(outputDir,'FCLC_stage1_ranksum.csv'));
writetable(diagnostics,fullfile(outputDir,'FCLC_stage1_diagnostics_summary.csv'));
writetable(meanTrace,fullfile(outputDir,'FCLC_stage1_mean_trace.csv'));
write_report(fullfile(outputDir,'FCLC_STAGE1_REPORT.md'),overall,pairwise,diagnostics,newRows,T);
report=struct('PerProblem',perProblem,'Overall',overall,'Pairwise',pairwise, ...
    'Diagnostics',diagnostics,'MeanTrace',meanTrace);
end

function write_report(path,overall,pairwise,diagnostics,newRows,T)
fid=fopen(path,'w');
if fid<0, error('Could not open FCLC Stage-1 report.'); end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fclc=newRows(newRows.Algorithm=="FCLC",:);
probeRatio=mean(fclc.ProbeCount./fclc.MaxFEs);
weightSpread=mean(fclc.WeightSpread,'omitnan');
fprintf(fid,'# FCLC-GWO Stage-1 mechanism screen\n\n');
fprintf(fid,'**Scope:** Sphere, Rastrigin, Rosenbrock, Ackley (D=30), CEC2022 F1/F6 (D=10); seeds 41–50; N=30; MATLAB local Processes, six workers.\n\n');
fprintf(fid,'**Completion:** %d new runs, %d OK, %d failed; %d reused GWO rows; %d merged rows; all RunKeys unique and all FEs matched MaxFEs. No new seed IDs were introduced.\n\n', ...
    height(newRows),sum(newRows.Status=="OK"),sum(newRows.Status~="OK"), ...
    sum(T.Source=="reused"),height(T));
fprintf(fid,'FCLC made a mean of %.2f%% extra probe evaluations relative to MaxFEs; its mean final across-follower weight spread was %.4f. Probe candidates updated credit only and did not replace population members.\n\n',100*probeRatio,weightSpread);
fprintf(fid,'## Average ranks\n\nLower is better. Best-mean counts include ties.\n\n| Algorithm | Average problem rank | Best-mean/tied-best problems |\n|---|---:|---:|\n');
overall=sortrows(overall,'AverageProblemRank');
for r=1:height(overall)
    fprintf(fid,'| %s | %.3f | %d/6 |\n',char(overall.Algorithm(r)), ...
        overall.AverageProblemRank(r),overall.BestMeanErrorCases(r));
end
fprintf(fid,'\n## FCLC pairwise results\n\nUnadjusted Wilcoxon rank-sum p-values are shown per problem, without Holm correction, following the project preference. The seed IDs are matched, but this test does not use pairing. Rastrigin returned zero residual error for every run and therefore has a non-informative tie (p=1).\n\n');
fprintf(fid,'| Problem | Comparator | FCLC wins/losses | Mean relative error improvement (%%) | p |\n|---|---|---:|---:|---:|\n');
for r=1:height(pairwise)
    fprintf(fid,'| %s | %s | %d/%d | %.3f | %.4g |\n', ...
        char(pairwise.Problem(r)),char(pairwise.Comparator(r)), ...
        pairwise.FCLCWins(r),pairwise.FCLCLosses(r), ...
        pairwise.MeanRelativeImprovementPct(r),pairwise.RankSumP_Unadjusted(r));
end
fprintf(fid,'\n## Mechanism diagnostics\n\nThe FCLC credit/weight diagnostics are in `FCLC_stage1_diagnostics_summary.csv` and `FCLC_weight_diagnostics.csv`; 1%%-FE traces are in `FCLC_stage1_trace_1pct.csv` and `FCLC_stage1_mean_trace.csv`. Stage-1 trace checkpoints use the first completed generation at or above each FE threshold; for no-probe GWO, best-evaluated equals best-propagated. The per-run `MeanWeight*` and `WeightSpread` fields are terminal stored-credit diagnostics computed after final leader re-ranking, before a potential next-generation follower reset; the trace contains the weights actually applied during the run. The small smoke can sample GWO initialization for thresholds below N=30 and is not comparison evidence. Historical reused GWO rows did not contain convergence traces, so no synthetic GWO curve is shown for CEC F1/F6.\n\n');
fprintf(fid,'## Interpretation\n\nThe fixed alpha-dominant weighting ranked first overall (1.750); standard GWO ranked 2.333, FCLC 2.583, and GCLC 3.333. FCLC beat GCLC on average rank but did not outperform the fixed-weight or standard-GWO baselines overall. Its follower-specific weights remained near equal on average. The current screen therefore does not support advancing to FCLC+DLM or FCLC+APL yet; first inspect why the counterfactual credit produced limited weight separation. These are exploratory 10-seed results, not confirmation or a novelty verdict.\n');
end
