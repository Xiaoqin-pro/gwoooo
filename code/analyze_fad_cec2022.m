function report=analyze_fad_cec2022(mergedCsv,outputDir)
% Analyze FAD-GWO against reused B0-B4 seed-matched baselines.
if nargin<1 || isempty(mergedCsv)
    mergedCsv=fullfile(gwo_project_root(),'results','fad_gwo_6worker_dev','B0_B5_merged.csv');
end
if nargin<2 || isempty(outputDir), outputDir=fileparts(mergedCsv); end
T=readtable(mergedCsv,'TextType','string');
optimum=[300 400 600 800 900 1800 2000 2200 2300 2400 2600 2700];
T.Error=max(T.BestFitness-optimum(T.Function)',0);
variants=["B0_GWO","B1_APLweighted","B2_APL_DLM2","B3_APL_BDL50", ...
    "B4_APL_DLM2_BDL50","B5_FAD"];
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
            samples{v}=rows.Error; means(v)=mean(rows.Error);
            medians(v)=median(rows.Error); sds(v)=std(rows.Error);
        end
        rr=tiedrank(means); rankSum=rankSum+rr'; bestCount=bestCount+(means==min(means))';
        row={func,dim};
        for v=1:numel(variants)
            row=[row,{means(v),medians(v),sds(v),rr(v)}]; %#ok<AGROW>
        end
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

pairRows=cell(5*numel(funcs)*numel(dims),9); holmP=nan(size(pairRows,1),1); q=0;
for v=1:5
    pvals=nan(numel(funcs)*numel(dims),1);
    for j=1:numel(funcs)*numel(dims)
        f=perFunction.Function(j); d=perFunction.Dimension(j);
        method=variants(6); comparator=variants(v);
        a=T.Error(T.Function==f & T.Dimension==d & T.Algorithm==method);
        b=T.Error(T.Function==f & T.Dimension==d & T.Algorithm==comparator);
        sa=T.Seed(T.Function==f & T.Dimension==d & T.Algorithm==method);
        sb=T.Seed(T.Function==f & T.Dimension==d & T.Algorithm==comparator);
        [sa,ia]=sort(sa); [sb,ib]=sort(sb); a=a(ia); b=b(ib);
        if ~isequal(sa,sb), error('Paired seed mismatch for %s.',comparator); end
        q=q+1; p=signrank(a,b); pvals(j)=p; diff=a-b;
        pairRows(q,:)={f,d,method,comparator,numel(a),sum(diff<0),sum(diff>0), ...
            median(diff),p};
    end
    first=(v-1)*numel(funcs)*numel(dims)+1;
    idx=first:first+numel(funcs)*numel(dims)-1;
    holmP(idx)=holm_adjust(pvals);
end
pairwise=cell2table(pairRows,'VariableNames', ...
    {'Function','Dimension','Method','Comparator','NSeeds','B5Wins','B5Losses', ...
    'MedianErrorDifference','SignedRankP_Raw'});
pairwise.Method=string(pairwise.Method); pairwise.Comparator=string(pairwise.Comparator);
pairwise.HolmP=holmP;
if ~exist(outputDir,'dir'), mkdir(outputDir); end
writetable(perFunction,fullfile(outputDir,'FAD_per_function.csv'));
writetable(overall,fullfile(outputDir,'FAD_algorithm_summary.csv'));
writetable(pairwise,fullfile(outputDir,'FAD_signedrank_holm.csv'));
writetable(friedmanTable,fullfile(outputDir,'FAD_friedman_by_function.csv'));
report=struct('PerFunction',perFunction,'Overall',overall,'Pairwise',pairwise,'Friedman',friedmanTable);
end

function adjusted=holm_adjust(p)
adjusted=nan(size(p)); valid=find(isfinite(p));
if isempty(valid), return; end
[sortedP,ord]=sort(p(valid)); m=numel(sortedP);
step=min(cummax((m-(1:m)'+1).*sortedP),1);
adjusted(valid(ord))=step;
end
