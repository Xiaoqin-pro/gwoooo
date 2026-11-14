function report = analyze_stage1_A0_A5(mergedCsv,outputDir)
% Compare reused A0 with only the newly executed A1-A5 stage-1 variants.
if nargin<1 || isempty(mergedCsv)
    mergedCsv=fullfile(gwo_project_root(),'results', ...
        'cec2022_stage1_missing_6worker','A0_A5_merged.csv');
end
if nargin<2 || isempty(outputDir), outputDir=fileparts(mergedCsv); end
T=readtable(mergedCsv,'TextType','string');
optimum=[300 400 600 800 900 1800 2000 2200 2300 2400 2600 2700];
T.Error=max(T.BestFitness-optimum(T.Function)',0);
variants=["A0_APLweighted","A1_DLM1","A2_DLM2","A3_BDLrank","A4_BDL50","A5_PTLP"];
funcs=unique(T.Function)'; dims=unique(T.Dimension)';
perRows=cell(numel(funcs)*numel(dims),26); rankSum=zeros(numel(variants),1);
bestCount=zeros(numel(variants),1); friedmanRows=cell(numel(funcs)*numel(dims),4);
pairs=cell(numel(variants)-1,numel(funcs)*numel(dims),9);
pairs(:)={NaN};
problem=0;
for dim=dims
    for func=funcs
        problem=problem+1; means=nan(1,numel(variants)); meds=means; stdevs=means;
        samples=cell(1,numel(variants)); seedVectors=cell(1,numel(variants));
        for v=1:numel(variants)
            rows=T(T.Dimension==dim & T.Function==func & T.Algorithm==variants(v),:);
            [sv,ord]=sort(rows.Seed); rows=rows(ord,:); seedVectors{v}=sv;
            samples{v}=rows.Error; means(v)=mean(rows.Error); meds(v)=median(rows.Error); stdevs(v)=std(rows.Error);
        end
        r=tiedrank(means); rankSum=rankSum+r'; bestCount=bestCount+(means==min(means))';
        perRows(problem,:)={func,dim, ...
            means(1),meds(1),stdevs(1),r(1), means(2),meds(2),stdevs(2),r(2), ...
            means(3),meds(3),stdevs(3),r(3), means(4),meds(4),stdevs(4),r(4), ...
            means(5),meds(5),stdevs(5),r(5), means(6),meds(6),stdevs(6),r(6)};
        X=zeros(numel(samples{1}),numel(variants));
        for v=1:numel(variants)
            if ~isequal(seedVectors{1},seedVectors{v})
                error('Seed mismatch for F%d D=%d variant %s.',func,dim,variants(v));
            end
            X(:,v)=samples{v};
        end
        friedmanRows(problem,:)={func,dim,friedman(X,1,'off'),variants(find(means==min(means),1))};
        for v=2:numel(variants)
            dErr=samples{v}-samples{1};
            p=signrank(samples{v},samples{1});
            pairs{v-1,problem,1}=func; pairs{v-1,problem,2}=dim;
            pairs{v-1,problem,3}=variants(v); pairs{v-1,problem,4}=numel(dErr);
            pairs{v-1,problem,5}=sum(dErr<0); pairs{v-1,problem,6}=sum(dErr>0);
            pairs{v-1,problem,7}=sum(dErr==0); pairs{v-1,problem,8}=median(dErr);
            pairs{v-1,problem,9}=p;
        end
    end
end

perNames={'Function','Dimension'};
for v=1:numel(variants)
    tag=char(variants(v));
    perNames=[perNames,{[tag '_MeanError'],[tag '_MedianError'], ...
        [tag '_StdError'],[tag '_Rank']}]; %#ok<AGROW>
end
perFunction=cell2table(perRows,'VariableNames',perNames);
overall=table(variants',rankSum/(numel(funcs)*numel(dims)),bestCount, ...
    'VariableNames',{'Algorithm','AverageFunctionRank','BestMeanErrorCases'});
friedmanTable=cell2table(friedmanRows,'VariableNames', ...
    {'Function','Dimension','FriedmanP_Unadjusted','BestMeanVariant'});
friedmanTable.BestMeanVariant=string(friedmanTable.BestMeanVariant);

pairRows=cell((numel(variants)-1)*numel(funcs)*numel(dims),9); q=0;
holmByRow=nan(size(pairRows,1),1);
for v=1:(numel(variants)-1)
    pvals=nan(numel(funcs)*numel(dims),1);
    for j=1:numel(funcs)*numel(dims)
        q=q+1; vals=cell(1,9);
        for k=1:9, vals{k}=pairs{v,j,k}; end
        pairRows(q,:)=vals; pvals(j)=vals{9};
    end
    adjusted=holm_adjust(pvals);
    rowStart=(v-1)*numel(funcs)*numel(dims)+1; rowEnd=v*numel(funcs)*numel(dims);
    % Append one adjusted-p column after creating the base comparison table.
    holmByRow(rowStart:rowEnd,1)=adjusted; %#ok<AGROW>
end
pairwise=cell2table(pairRows,'VariableNames', ...
    {'Function','Dimension','Algorithm','NSeeds','WinsVsA0','LossesVsA0', ...
    'Ties','MedianErrorDifference','SignedRankP_Raw'});
pairwise.Algorithm=string(pairwise.Algorithm);
pairwise.HolmP=holmByRow;

if ~exist(outputDir,'dir'), mkdir(outputDir); end
writetable(perFunction,fullfile(outputDir,'A0_A5_per_function.csv'));
writetable(overall,fullfile(outputDir,'A0_A5_algorithm_summary.csv'));
writetable(pairwise,fullfile(outputDir,'A0_A5_signedrank_holm.csv'));
writetable(friedmanTable,fullfile(outputDir,'A0_A5_friedman.csv'));
report=struct('PerFunction',perFunction,'Overall',overall,'Pairwise',pairwise, ...
    'Friedman',friedmanTable);
end

function adjusted=holm_adjust(p)
adjusted=nan(size(p)); valid=find(isfinite(p));
if isempty(valid), return; end
[sortedP,ord]=sort(p(valid)); m=numel(sortedP);
step=min(cummax((m-(1:m)'+1).*sortedP),1);
adjusted(valid(ord))=step;
end
