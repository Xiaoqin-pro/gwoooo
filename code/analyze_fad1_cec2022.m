function report=analyze_fad1_cec2022(mergedCsv,traceCsv,outputDir)
% Compare FAD-1 against seed-matched B0-B5; reuse historical FAD-0 results.
root=gwo_project_root();
if nargin<1 || isempty(mergedCsv)
    mergedCsv=fullfile(root,'results','fad1_no_individual_fallback_6worker_dev','B0_B6_merged.csv');
end
if nargin<2 || isempty(traceCsv)
    traceCsv=fullfile(root,'results','fad1_no_individual_fallback_6worker_dev','FAD1_search_trace_1pct.csv');
end
if nargin<3 || isempty(outputDir), outputDir=fileparts(mergedCsv); end
T=readtable(mergedCsv,'TextType','string');
optimum=[300 400 600 800 900 1800 2000 2200 2300 2400 2600 2700];
T.Error=max(T.BestFitness-optimum(T.Function)',0);
variants=["B0_GWO","B1_APLweighted","B2_APL_DLM2","B3_APL_BDL50", ...
    "B4_APL_DLM2_BDL50","B5_FAD","B6_FAD1_NoIndFallback"];
funcs=unique(T.Function)'; dims=unique(T.Dimension)';
perRows=cell(numel(funcs)*numel(dims),2+4*numel(variants));
rankSum=zeros(numel(variants),1); bestCount=zeros(numel(variants),1);
friedmanRows=cell(numel(funcs)*numel(dims),4); pidx=0;
for dim=dims
    for func=funcs
        pidx=pidx+1; means=nan(1,numel(variants)); medians=means; sds=means;
        samples=cell(1,numel(variants)); seedsByVariant=cell(1,numel(variants));
        for v=1:numel(variants)
            rows=T(T.Dimension==dim & T.Function==func & T.Algorithm==variants(v),:);
            [seedsByVariant{v},ord]=sort(rows.Seed); rows=rows(ord,:);
            if height(rows)~=10 || any(rows.Status~="OK")
                error('Incomplete run set for %s F%d D%d.',variants(v),func,dim);
            end
            expected=zeros(height(rows),1); expected(rows.Dimension==10)=200000; expected(rows.Dimension==20)=1000000;
            if any(rows.FEs~=expected), error('FE budget mismatch for %s F%d D%d.',variants(v),func,dim); end
            samples{v}=rows.Error; means(v)=mean(rows.Error);
            medians(v)=median(rows.Error); sds(v)=std(rows.Error);
        end
        rr=tiedrank(means); rankSum=rankSum+rr'; bestCount=bestCount+(means==min(means))';
        row={func,dim};
        for v=1:numel(variants), row=[row,{means(v),medians(v),sds(v),rr(v)}]; end %#ok<AGROW>
        perRows(pidx,:)=row;
        X=zeros(10,numel(variants));
        for v=1:numel(variants)
            if ~isequal(seedsByVariant{1},seedsByVariant{v})
                error('Seed mismatch at F%d D%d.',func,dim);
            end
            X(:,v)=samples{v};
        end
        friedmanRows(pidx,:)={func,dim,friedman(X,1,'off'),variants(find(means==min(means),1))};
    end
end
names={'Function','Dimension'};
for v=1:numel(variants)
    tag=char(variants(v)); names=[names,{[tag '_MeanError'],[tag '_MedianError'], ...
        [tag '_StdError'],[tag '_Rank']}]; %#ok<AGROW>
end
perFunction=cell2table(perRows,'VariableNames',names);
overall=table(variants',rankSum/(numel(funcs)*numel(dims)),bestCount, ...
    'VariableNames',{'Algorithm','AverageFunctionRank','BestMeanErrorCases'});
friedmanTable=cell2table(friedmanRows,'VariableNames', ...
    {'Function','Dimension','FriedmanP_Unadjusted','BestMeanVariant'});
friedmanTable.BestMeanVariant=string(friedmanTable.BestMeanVariant);

comparators=variants(1:end-1); pairRows=cell(numel(comparators)*numel(funcs)*numel(dims),9);
holmP=nan(size(pairRows,1),1); q=0;
for v=1:numel(comparators)
    pvals=nan(numel(funcs)*numel(dims),1);
    for j=1:numel(funcs)*numel(dims)
        f=perFunction.Function(j); d=perFunction.Dimension(j);
        a=T.Error(T.Function==f & T.Dimension==d & T.Algorithm==variants(end));
        b=T.Error(T.Function==f & T.Dimension==d & T.Algorithm==comparators(v));
        sa=T.Seed(T.Function==f & T.Dimension==d & T.Algorithm==variants(end));
        sb=T.Seed(T.Function==f & T.Dimension==d & T.Algorithm==comparators(v));
        [sa,ia]=sort(sa); [sb,ib]=sort(sb); a=a(ia); b=b(ib);
        if ~isequal(sa,sb), error('Paired seed mismatch for %s.',comparators(v)); end
        q=q+1; p=signrank(a,b); pvals(j)=p; diff=a-b;
        pairRows(q,:)={f,d,variants(end),comparators(v),numel(a),sum(diff<0),sum(diff>0),median(diff),p};
    end
    idx=(v-1)*numel(funcs)*numel(dims)+(1:numel(funcs)*numel(dims));
    holmP(idx)=holm_adjust(pvals);
end
pairwise=cell2table(pairRows,'VariableNames', ...
    {'Function','Dimension','Method','Comparator','NSeeds','FAD1Wins','FAD1Losses', ...
    'MedianErrorDifference','SignedRankP_Raw'});
pairwise.Method=string(pairwise.Method); pairwise.Comparator=string(pairwise.Comparator);
pairwise.HolmP=holmP;

rawFAD1=readtable(fullfile(outputDir,'B6_FAD1_new_runs.csv'),'TextType','string');
diagnosticSummary=groupsummary(rawFAD1,{'Function','Dimension'},'mean', ...
    {'Seconds','APLGatePassRate','DLM1SuccessRate','DLM2SuccessRate', ...
    'IndividualFallbackCount','GenerationFallbackCount','FallbackCount'});

trace=readtable(traceCsv,'TextType','string');
convRows=cell(height(trace)*100,6); q=0;
for r=1:height(trace)
    f=trace.Function(r); opt=optimum(f);
    for p=1:100
        q=q+1; col=sprintf('BestFEpct_%02d',p); vals=trace.(col);
        convRows(q,:)={trace.Algorithm(r),f,trace.Dimension(r),trace.Seed(r),p, ...
            max(vals(r)-opt,0)};
    end
end
convLong=cell2table(convRows,'VariableNames', ...
    {'Algorithm','Function','Dimension','Seed','FEPercent','Error'});
convLong.Algorithm=string(convLong.Algorithm);
convMean=groupsummary(convLong,{'Algorithm','Function','Dimension','FEPercent'}, ...
    {'mean','std'},{'Error'});

% Historical FAD-0 saved diversity only. Reuse it with the new FAD-1 traces.
oldTrace=readtable(fullfile(root,'results','fad_gwo_6worker_dev','FAD_diversity_trace_1pct.csv'), ...
    'TextType','string');
divRows=cell((height(oldTrace)+height(trace))*100,5); q=0;
for r=1:height(oldTrace)
    for p=1:100
        q=q+1; col=sprintf('FEpct_%02d',p); vals=oldTrace.(col);
        divRows(q,:)={"B5_FAD",oldTrace.Function(r),oldTrace.Dimension(r),p,vals(r)};
    end
end
for r=1:height(trace)
    for p=1:100
        q=q+1; col=sprintf('DiversityFEpct_%02d',p); vals=trace.(col);
        divRows(q,:)={"B6_FAD1_NoIndFallback",trace.Function(r),trace.Dimension(r),p,vals(r)};
    end
end
divLong=cell2table(divRows,'VariableNames',{'Algorithm','Function','Dimension','FEPercent','Diversity'});
divLong.Algorithm=string(divLong.Algorithm);
divMean=groupsummary(divLong,{'Algorithm','Function','Dimension','FEPercent'}, ...
    {'mean','std'},{'Diversity'});

if ~isfolder(outputDir), mkdir(outputDir); end
writetable(perFunction,fullfile(outputDir,'FAD1_per_function.csv'));
writetable(overall,fullfile(outputDir,'FAD1_algorithm_summary.csv'));
writetable(pairwise,fullfile(outputDir,'FAD1_signedrank_holm.csv'));
writetable(friedmanTable,fullfile(outputDir,'FAD1_friedman_by_function.csv'));
writetable(diagnosticSummary,fullfile(outputDir,'FAD1_diagnostics_summary.csv'));
writetable(convLong,fullfile(outputDir,'FAD1_convergence_by_run.csv'));
writetable(convMean,fullfile(outputDir,'FAD1_mean_convergence.csv'));
writetable(divMean,fullfile(outputDir,'FAD0_FAD1_mean_diversity.csv'));
report=struct('PerFunction',perFunction,'Overall',overall,'Pairwise',pairwise, ...
    'Friedman',friedmanTable,'Diagnostics',diagnosticSummary, ...
    'Convergence',convMean,'Diversity',divMean);
end

function adjusted=holm_adjust(p)
adjusted=nan(size(p)); valid=find(isfinite(p));
if isempty(valid), return; end
[sortedP,ord]=sort(p(valid)); m=numel(sortedP);
step=min(cummax((m-(1:m)'+1).*sortedP),1);
adjusted(valid(ord))=step;
end
