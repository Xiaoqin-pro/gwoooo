function merged=run_apl_handoff_cec2022(outputDir,workerCount,seeds,functionIds,dims)
%RUN_APL_HANDOFF_CEC2022 Run A8/A9 only and reuse matching A0/A2/A7 results.
if nargin<1 || isempty(outputDir)
    outputDir=fullfile(gwo_project_root(),'results','apl_handoff_6worker_dev');
end
if nargin<2 || isempty(workerCount), workerCount=6; end
if nargin<3 || isempty(seeds), seeds=41:50; end
if nargin<4 || isempty(functionIds), functionIds=1:12; end
if nargin<5 || isempty(dims), dims=[10 20]; end
root=gwo_project_root(); codeRoot=fileparts(mfilename('fullpath'));
benchRoot=fullfile(root,'data','CEC2022_reference');
if ~isfile(fullfile(benchRoot,'cec22_test_func.mexw64'))
    error('CEC2022 reference MEX is missing from data/CEC2022_reference.');
end
if ~isfolder(outputDir), mkdir(outputDir); end
base=load_handoff_baselines(root,seeds,functionIds,dims);
rawCsv=fullfile(outputDir,'A8_A9_new_runs.csv');
mergedCsv=fullfile(outputDir,'A0_A2_A7_A8_A9_merged.csv');
traceCsv=fullfile(outputDir,'A8_A9_diversity_trace_1pct.csv');
checkpoint=fullfile(outputDir,'APL_handoff_checkpoint.mat');
variants={'apl_handoff_archive','apl_handoff_strict'};
algorithms={'A8_APL_HandoffArchive','A9_APL_HandoffStrict'};
diagNames={'APLGatePassRate','Pattern3Evaluations','Pattern4Evaluations', ...
    'Pattern5Evaluations','Pattern3Successes','Pattern4Successes','Pattern5Successes', ...
    'ArchiveSelections','BDLMeanK','DLMCount','DLMSuccess','DoubleDLMCount', ...
    'DoubleDLMSuccess','HandoffOpportunities','HandoffTriggers','StrictRetains', ...
    'FallbackEvaluations'};
runNames={'Function','Dimension','Seed','Algorithm','BestFitness','MeanFitness', ...
    'StdFitness','FEs','MaxFEs','Generations','Seconds','Status','RunKey','Source',diagNames{:}};
traceNames=arrayfun(@(k)sprintf('FEpct_%02d',k),1:100,'UniformOutput',false);
if isfile(rawCsv)
    newRows=readtable(rawCsv,'TextType','string');
    if isfile(traceCsv), traceRows=readtable(traceCsv,'TextType','string'); else, traceRows=table(); end
else
    newRows=empty_handoff_table(runNames); traceRows=table();
end

addpath(codeRoot); addpath(benchRoot);
pool=gcp('nocreate');
if isempty(pool), pool=parpool('local',workerCount);
elseif pool.NumWorkers~=workerCount
    error('Existing pool uses %d workers; requested %d.',pool.NumWorkers,workerCount);
end
oldDir=pwd; restoreDir=onCleanup(@()cd(oldDir)); %#ok<NASGU>
cd(benchRoot);
pctRunOnAll(sprintf('cd(''%s''); addpath(''%s''); addpath(''%s'');',benchRoot,benchRoot,codeRoot));

expectedNew=numel(functionIds)*numel(dims)*numel(seeds)*numel(variants);
for dim=dims
    if dim==10, maxFEs=200000; else, maxFEs=1000000; end
    lb=-100*ones(1,dim); ub=100*ones(1,dim);
    for fun=functionIds
        keys=cell(numel(seeds)*numel(variants),1); q=0;
        for s=seeds
            for v=1:numel(variants)
                q=q+1; keys{q}=sprintf('F%02d_D%02d_S%04d_%s', ...
                    fun,dim,s,algorithms{v});
            end
        end
        if isempty(newRows), pending=1:numel(keys);
        else, pending=find(~ismember(string(keys),newRows.RunKey(newRows.Status=="OK"))); end
        if isempty(pending)
            fprintf('Skip completed A8/A9 block F%d D=%d.\n',fun,dim); continue;
        end
        rows=cell(numel(pending),numel(runNames)); traces=cell(numel(pending),105);
        parfor q=1:numel(pending)
            taskIndex=pending(q); seedIndex=ceil(taskIndex/numel(variants));
            variantIndex=mod(taskIndex-1,numel(variants))+1;
            seed=seeds(seedIndex); variant=variants{variantIndex};
            algorithm=algorithms{variantIndex}; key=keys{taskIndex}; t=tic;
            try
                objective=@(x)cec2022_objective(x,fun);
                opts=struct('PopulationSize',30,'MaxFEs',maxFEs,'Seed',seed, ...
                    'Variant',variant,'DLMFraction',0.20,'EliteCount',3, ...
                    'LaplaceMu',0.6,'LaplaceSigma',0.3,'BDLFraction',0.5);
                out=gwo_optimize_apl_stage1(objective,lb,ub,opts); dg=out.Diagnostics;
                values={fun,dim,seed,algorithm,out.BestFitness,out.MeanFitness,out.StdFitness, ...
                    out.FEs,maxFEs,out.Generations,toc(t),'OK',key,'new', ...
                    dg.APLGatePassRate,dg.PatternEvaluations(1),dg.PatternEvaluations(2), ...
                    dg.PatternEvaluations(3),dg.PatternSuccesses(1),dg.PatternSuccesses(2), ...
                    dg.PatternSuccesses(3),dg.ArchiveSelections,dg.BDLMeanK,dg.DLMCount, ...
                    dg.DLMSuccess,dg.DoubleDLMCount,dg.DoubleDLMSuccess, ...
                    dg.HandoffOpportunities,dg.HandoffTriggers,dg.StrictRetains,dg.FallbackEvaluations};
                rows(q,:)=values;
                traces(q,:)=[{fun,dim,seed,algorithm,key},num2cell(out.Trace.Diversity(:)')];
            catch ME
                values={fun,dim,seed,algorithm,NaN,NaN,NaN,NaN,maxFEs,NaN,toc(t), ...
                    char(string(ME.message)),key,'new'};
                rows(q,:)=[values,num2cell(nan(1,numel(diagNames)))];
                traces(q,:)=[{fun,dim,seed,algorithm,key},num2cell(nan(1,100))];
            end
        end
        block=cell2table(rows,'VariableNames',runNames);
        block.Algorithm=string(block.Algorithm); block.Status=string(block.Status);
        block.RunKey=string(block.RunKey); block.Source=string(block.Source);
        traceBlock=cell2table(traces,'VariableNames',[ ...
            {'Function','Dimension','Seed','Algorithm','RunKey'},traceNames]);
        traceBlock.Algorithm=string(traceBlock.Algorithm); traceBlock.RunKey=string(traceBlock.RunKey);
        replaceKeys=string(keys(pending));
        if ~isempty(newRows), newRows=newRows(~ismember(newRows.RunKey,replaceKeys),:); end
        if ~isempty(traceRows), traceRows=traceRows(~ismember(traceRows.RunKey,replaceKeys),:); end
        newRows=[newRows;block]; traceRows=[traceRows;traceBlock]; %#ok<AGROW>
        merged=[base;newRows];
        writetable(newRows,rawCsv); writetable(merged,mergedCsv); writetable(traceRows,traceCsv);
        save(checkpoint,'base','newRows','merged','traceRows','seeds','variants');
        fprintf('Checkpoint: F%d D=%d; A8/A9 new %d/%d; reused rows=%d.\n', ...
            fun,dim,height(newRows),expectedNew,height(base));
    end
end
merged=[base;newRows];
end

function base=load_handoff_baselines(root,seeds,functionIds,dims)
src=readtable(fullfile(root,'results','cec2022_stage2_combo_6worker','A0_A7_merged.csv'), ...
    'TextType','string');
labels=["A0_APLweighted","A2_DLM2","A7_DLM2_BDL50"];
names={'Function','Dimension','Seed','Algorithm','BestFitness','MeanFitness','StdFitness', ...
    'FEs','MaxFEs','Generations','Seconds','Status','RunKey','Source', ...
    'APLGatePassRate','Pattern3Evaluations','Pattern4Evaluations','Pattern5Evaluations', ...
    'Pattern3Successes','Pattern4Successes','Pattern5Successes','ArchiveSelections', ...
    'BDLMeanK','DLMCount','DLMSuccess','DoubleDLMCount','DoubleDLMSuccess', ...
    'HandoffOpportunities','HandoffTriggers','StrictRetains','FallbackEvaluations'};
types=[{'double','double','double','string','double','double','double','double','double', ...
    'double','double','string','string','string'},repmat({'double'},1,numel(names)-14)];
base=table('Size',[0 numel(names)],'VariableTypes',types,'VariableNames',names);
for label=labels
    rows=src(src.Algorithm==label & ismember(src.Seed,seeds) & ...
        ismember(src.Function,functionIds) & ismember(src.Dimension,dims),:);
    expected=numel(functionIds)*numel(dims)*numel(seeds);
    if height(rows)~=expected || any(rows.Status~="OK")
        error('Reusable baseline %s is incomplete.',label);
    end
    values=cell(height(rows),numel(names));
    for i=1:height(rows)
        if rows.Dimension(i)==10, expectedFE=200000; else, expectedFE=1000000; end
        if rows.FEs(i)~=expectedFE, error('Reusable baseline %s has incompatible FEs.',label); end
        extras=nan(1,numel(names)-14);
        extras(2)=get_optional(rows,'Pattern3Evaluations',i);
        extras(3)=get_optional(rows,'Pattern4Evaluations',i);
        extras(4)=get_optional(rows,'Pattern5Evaluations',i);
        extras(5)=get_optional(rows,'Pattern3Successes',i);
        extras(6)=get_optional(rows,'Pattern4Successes',i);
        extras(7)=get_optional(rows,'Pattern5Successes',i);
        extras(8)=get_optional(rows,'ArchiveSelections',i);
        extras(9)=get_optional(rows,'BDLMeanK',i);
        extras(10)=get_optional(rows,'DLMCount',i);
        extras(11)=get_optional(rows,'DLMSuccess',i);
        extras(12)=get_optional(rows,'DoubleDLMCount',i);
        extras(13)=get_optional(rows,'DoubleDLMSuccess',i);
        values(i,:)=[{rows.Function(i),rows.Dimension(i),rows.Seed(i),char(label), ...
            rows.BestFitness(i),rows.MeanFitness(i),rows.StdFitness(i),rows.FEs(i), ...
            expectedFE,rows.Generations(i),rows.Seconds(i),'OK',char(rows.RunKey(i)),'reused'}, ...
            num2cell(extras)];
    end
    block=cell2table(values,'VariableNames',names);
    block.Algorithm=string(block.Algorithm); block.Status=string(block.Status);
    block.RunKey=string(block.RunKey); block.Source=string(block.Source);
    base=[base;block]; %#ok<AGROW>
end
end

function T=empty_handoff_table(names)
types=[{'double','double','double','string','double','double','double','double', ...
    'double','double','double','string','string','string'},repmat({'double'},1,numel(names)-14)];
T=table('Size',[0 numel(names)],'VariableTypes',types,'VariableNames',names);
end

function x=get_optional(T,name,row)
if ismember(name,T.Properties.VariableNames)
    values=T.(name); x=values(row);
else
    x=NaN;
end
end
