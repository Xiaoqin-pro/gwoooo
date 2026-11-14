function report=analyze_stage2_A0_A7(mergedCsv,outputDir)
% Analyze reused A0-A5 plus newly-run A6/A7 stage-2 combinations.
if nargin<1 || isempty(mergedCsv)
    mergedCsv=fullfile(gwo_project_root(),'results', ...
        'cec2022_stage2_combo_6worker','A0_A7_merged.csv');
end
if nargin<2 || isempty(outputDir), outputDir=fileparts(mergedCsv); end
T=readtable(mergedCsv,'TextType','string');
optimum=[300 400 600 800 900 1800 2000 2200 2300 2400 2600 2700];
T.Error=max(T.BestFitness-optimum(T.Function)',0);
variants=["A0_APLweighted","A1_DLM1","A2_DLM2","A3_BDLrank", ...
    "A4_BDL50","A5_PTLP","A6_DLM2_BDLrank","A7_DLM2_BDL50"];
funcs=unique(T.Function)'; dims=unique(T.Dimension)';
perRows=cell(numel(funcs)*numel(dims),2+4*numel(variants));
rankSum=zeros(numel(variants),1); bestCount=zeros(numel(variants),1);
friedmanRows=cell(numel(funcs)*numel(dims),4); pairs=cell(12,numel(funcs)*numel(dims),9);
problem=0;
for dim=dims
    for func=funcs
        problem=problem+1; means=nan(1,numel(variants)); meds=means; sds=means;
        samples=cell(1,numel(variants)); seedSets=cell(1,numel(variants));
        for v=1:numel(variants)
            rows=T(T.Dimension==dim & T.Function==func & T.Algorithm==variants(v),:);
            [seedSets{v},ord]=sort(rows.Seed); rows=rows(ord,:);
            if height(rows)~=10, error('Expected 10 rows for %s F%d D%d.',variants(v),func,dim); end
            samples{v}=rows.Error; means(v)=mean(rows.Error); meds(v)=median(rows.Error); sds(v)=std(rows.Error);
        end
        rr=tiedrank(means); rankSum=rankSum+rr'; bestCount=bestCount+(means==min(means))';
        x={func,dim};
        for v=1:numel(variants), x=[x,{means(v),meds(v),sds(v),rr(v)}]; end %#ok<AGROW>
        perRows(problem,:)=x;
        X=zeros(10,numel(variants));
        for v=1:numel(variants)
            if ~isequal(seedSets{1},seedSets{v}), error('Seed mismatch at F%d D%d.',func,dim); end
            X(:,v)=samples{v};
        end
        friedmanRows(problem,:)={func,dim,friedman(X,1,'off'),variants(find(means==min(means),1))};
        compare={'A1_DLM1','A0_APLweighted'; 'A2_DLM2','A0_APLweighted'; ...
            'A3_BDLrank','A0_APLweighted'; 'A4_BDL50','A0_APLweighted'; ...
            'A5_PTLP','A0_APLweighted'; 'A6_DLM2_BDLrank','A0_APLweighted'; ...
            'A7_DLM2_BDL50','A0_APLweighted'; 'A6_DLM2_BDLrank','A2_DLM2'; ...
            'A6_DLM2_BDLrank','A3_BDLrank'; 'A7_DLM2_BDL50','A2_DLM2'; ...
            'A7_DLM2_BDL50','A4_BDL50'; 'A6_DLM2_BDLrank','A7_DLM2_BDL50'};
        for c=1:size(compare,1)
            m=string(compare{c,1}); b=string(compare{c,2});
            im=find(variants==m,1); ib=find(variants==b,1);
            z=samples{im}-samples{ib}; pv=signrank(samples{im},samples{ib});
            pairs{c,problem,1}=func; pairs{c,problem,2}=dim; pairs{c,problem,3}=m;
            pairs{c,problem,4}=b; pairs{c,problem,5}=sum(z<0); pairs{c,problem,6}=sum(z>0);
            pairs{c,problem,7}=sum(z==0); pairs{c,problem,8}=median(z); pairs{c,problem,9}=pv;
        end
    end
end

perNames={'Function','Dimension'};
for v=1:numel(variants)
    tag=char(variants(v)); perNames=[perNames,{[tag '_MeanError'],[tag '_MedianError'], ...
        [tag '_StdError'],[tag '_Rank']}]; %#ok<AGROW>
end
perFunction=cell2table(perRows,'VariableNames',perNames);
overall=table(variants',rankSum/(numel(funcs)*numel(dims)),bestCount, ...
    'VariableNames',{'Algorithm','AverageFunctionRank','BestMeanErrorCases'});
friedmanTable=cell2table(friedmanRows,'VariableNames', ...
    {'Function','Dimension','FriedmanP_Unadjusted','BestMeanVariant'});
friedmanTable.BestMeanVariant=string(friedmanTable.BestMeanVariant);
pairRows=cell(12*numel(funcs)*numel(dims),9); holmByRow=nan(size(pairRows,1),1); q=0;
for c=1:size(compare,1)
    pvals=nan(numel(funcs)*numel(dims),1);
    for j=1:numel(funcs)*numel(dims)
        q=q+1; vals=cell(1,9);
        for k=1:9, vals{k}=pairs{c,j,k}; end
        pairRows(q,:)=vals; pvals(j)=vals{9};
    end
    idx=(c-1)*numel(funcs)*numel(dims)+(1:numel(funcs)*numel(dims));
    holmByRow(idx)=holm_adjust(pvals);
end
pairwise=cell2table(pairRows,'VariableNames', ...
    {'Function','Dimension','Method','Comparator','Wins','Losses','Ties', ...
    'MedianErrorDifference','SignedRankP_Raw'});
pairwise.Method=string(pairwise.Method); pairwise.Comparator=string(pairwise.Comparator);
pairwise.HolmP=holmByRow;
if ~exist(outputDir,'dir'), mkdir(outputDir); end
writetable(perFunction,fullfile(outputDir,'A0_A7_per_function.csv'));
writetable(overall,fullfile(outputDir,'A0_A7_algorithm_summary.csv'));
writetable(pairwise,fullfile(outputDir,'A0_A7_signedrank_holm.csv'));
writetable(friedmanTable,fullfile(outputDir,'A0_A7_friedman.csv'));
report=struct('PerFunction',perFunction,'Overall',overall,'Pairwise',pairwise,'Friedman',friedmanTable);
end

function adjusted=holm_adjust(p)
adjusted=nan(size(p)); valid=find(isfinite(p));
if isempty(valid), return; end
[sortedP,ord]=sort(p(valid)); m=numel(sortedP);
step=min(cummax((m-(1:m)'+1).*sortedP),1);
adjusted(valid(ord))=step;
end
