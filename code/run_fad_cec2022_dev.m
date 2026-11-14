function merged=run_fad_cec2022_dev(outputDir,seeds,workerCount,functionIds,dims)
% Run only the new B5 FAD-GWO algorithm; reuse B0-B4 from seeds 41:50.
if nargin<1 || isempty(outputDir)
    outputDir=fullfile(gwo_project_root(),'results','fad_gwo_6worker_dev');
end
if nargin<2 || isempty(seeds), seeds=41:50; end
if nargin<3 || isempty(workerCount), workerCount=6; end
if nargin<4 || isempty(functionIds), functionIds=1:12; end
if nargin<5 || isempty(dims), dims=[10 20]; end
root=gwo_project_root(); codeRoot=fileparts(mfilename('fullpath'));
benchRoot=fullfile(root,'data','CEC2022_reference');
if ~isfolder(benchRoot) || ~isfile(fullfile(benchRoot,'cec22_test_func.mexw64'))
    error('CEC2022 reference MEX is missing from data/CEC2022_reference.');
end
if ~isfolder(outputDir), mkdir(outputDir); end
if ~isfile(fullfile(root,'results','cec2022_apl_v2_6worker_dev','cec2022_development.csv')) || ...
        ~isfile(fullfile(root,'results','cec2022_stage1_missing_6worker','A0_A5_merged.csv')) || ...
        ~isfile(fullfile(root,'results','cec2022_stage2_combo_6worker','A0_A7_merged.csv'))
    error('One or more reusable B0-B4 baseline result files are missing.');
end
base=load_fad_baselines(root,seeds);
rawCsv=fullfile(outputDir,'B5_FAD_new_runs.csv');
mergedCsv=fullfile(outputDir,'B0_B5_merged.csv');
traceCsv=fullfile(outputDir,'FAD_diversity_trace_1pct.csv');
dimCsv=fullfile(outputDir,'FAD_dimension_diagnostics.csv');
diagNames={'MeanFinalState','MaxFinalState','MeanK','DLMSelectedMean','APLGatePassRate', ...
    'Pattern3Evaluations','Pattern4Evaluations','Pattern5Evaluations', ...
    'Pattern3Successes','Pattern4Successes','Pattern5Successes', ...
    'DLM1Attempts','DLM1Successes','DLM1SuccessRate','DLM2Attempts', ...
    'DLM2Successes','DLM2SuccessRate','FallbackCount','DimensionMemoryUpdates'};
traceNames=arrayfun(@(k)sprintf('FEpct_%02d',k),1:100,'UniformOutput',false);
diagNames={'MeanFinalState','MaxFinalState','MeanK','DLMSelectedMean','APLGatePassRate', ...
    'Pattern3Evaluations','Pattern4Evaluations','Pattern5Evaluations', ...
    'Pattern3Successes','Pattern4Successes','Pattern5Successes', ...
    'DLM1Attempts','DLM1Successes','DLM1SuccessRate','DLM2Attempts', ...
    'DLM2Successes','DLM2SuccessRate','FallbackCount','DimensionMemoryUpdates'};
allNames=[{'Algorithm','Function','Dimension','Seed','BestFitness','MeanFitness', ...
    'StdFitness','FEs','Generations','Seconds','Status','RunKey','Source'},diagNames];
if isfile(rawCsv)
    newRows=readtable(rawCsv,'TextType','string');
    traceRows=readtable(traceCsv,'TextType','string');
    if isfile(dimCsv)
        try
            dimRows=readtable(dimCsv,'TextType','string');
            if ~ismember('RunKey',dimRows.Properties.VariableNames), dimRows=table(); end
        catch
            dimRows=table();
        end
    else
        dimRows=table();
    end
else
    newRows=table(); traceRows=table(); dimRows=table();
end
merged=base;
if ~isempty(newRows), merged=[base;newRows]; end
addpath(codeRoot); addpath(benchRoot);
pool=gcp('nocreate');
if isempty(pool), pool=parpool('local',workerCount);
elseif pool.NumWorkers~=workerCount
    error('Existing pool uses %d workers; requested %d.',pool.NumWorkers,workerCount);
end
oldDir=pwd; restoreDir=onCleanup(@()cd(oldDir)); %#ok<NASGU>
cd(benchRoot);
pctRunOnAll(sprintf('cd(''%s''); addpath(''%s''); addpath(''%s'');',benchRoot,benchRoot,codeRoot));

totalExpected=numel(functionIds)*numel(dims)*numel(seeds);
for dim=dims
    if dim==10, maxFEs=200000; else, maxFEs=1000000; end
    lb=-100*ones(1,dim); ub=100*ones(1,dim);
    for fun=functionIds
        keys=arrayfun(@(s)sprintf('F%02d_D%02d_S%04d_B5_FAD',fun,dim,s),seeds,'UniformOutput',false)';
        if isempty(newRows), pending=1:numel(seeds);
        else, pending=find(~ismember(string(keys),newRows.RunKey(newRows.Status=="OK"))); end
        if isempty(pending)
            fprintf('Skip completed FAD block F%d D=%d.\n',fun,dim); continue;
        end
        runCells=cell(numel(pending),numel(allNames));
        traceCells=cell(numel(pending),105);
        dimData=cell(numel(pending),1);
        parfor q=1:numel(pending)
            sIndex=pending(q); seed=seeds(sIndex); key=keys{sIndex}; t=tic;
            try
                objective=@(x)cec2022_objective(x,fun);
                opts=struct('PopulationSize',30,'MaxFEs',maxFEs,'Seed',seed);
                out=gwo_optimize_fad(objective,lb,ub,opts);
                dg=out.Diagnostics;
                values={ 'B5_FAD',fun,dim,seed,out.BestFitness,out.MeanFitness, ...
                    out.StdFitness,out.FEs,out.Generations,toc(t),'OK',key,'new', ...
                    dg.MeanFinalState,dg.MaxFinalState,dg.MeanK,dg.DLMSelectedMean, ...
                    dg.APLGatePassRate,dg.PatternEvaluations(1),dg.PatternEvaluations(2), ...
                    dg.PatternEvaluations(3),dg.PatternSuccesses(1),dg.PatternSuccesses(2), ...
                    dg.PatternSuccesses(3),dg.DLMAttempts,dg.DLMSuccesses,dg.DLMFirstSuccessRate, ...
                    dg.DLMSecondAttempts,dg.DLMSecondSuccesses,dg.DLMSecondSuccessRate, ...
                    dg.FallbackCount,dg.DimensionMemoryUpdates};
                runCells(q,:)=values;
                traceCells(q,:)=[{'B5_FAD',fun,dim,seed,key},num2cell(out.Trace.Diversity(:)')];
                dd=dg.DimensionSuccessRate;
                dimData{q}=table(repmat("B5_FAD",dim,1),repmat(string(key),dim,1),(1:dim)', ...
                    repmat(fun,dim,1),repmat(dim,dim,1),repmat(seed,dim,1), ...
                    dg.DimensionSelectionCount(:),dg.DimensionSelectionRate(:), ...
                    dg.DimensionSuccessCredit(:),dg.DimensionFailureCredit(:),dd(:), ...
                    dg.DimensionCollapse(:),dg.InitialDimensionDiversity(:), ...
                    dg.FinalDimensionDiversity(:), ...
                    'VariableNames',{'Algorithm','RunKey','VariableIndex','Function','ProblemDimension', ...
                    'Seed','SelectionCount','SelectionRate','SuccessCredit','FailureCredit', ...
                    'SuccessRate','Collapse','InitialDiversity','FinalDiversity'});
            catch ME
                runCells(q,:)=[{'B5_FAD',fun,dim,seed,NaN,NaN,NaN,NaN,NaN,toc(t), ...
                    ME.message,key,'new'},num2cell(nan(1,numel(diagNames)))];
                traceCells(q,:)=[{'B5_FAD',fun,dim,seed,key},num2cell(nan(1,100))];
                dimData{q}=table();
            end
        end
        runNames={'Algorithm','Function','Dimension','Seed','BestFitness','MeanFitness', ...
            'StdFitness','FEs','Generations','Seconds','Status','RunKey','Source',diagNames{:}};
        block=cell2table(runCells,'VariableNames',runNames);
        block.Algorithm=string(block.Algorithm); block.Status=string(block.Status);
        block.RunKey=string(block.RunKey); block.Source=string(block.Source);
        traceBlock=cell2table(traceCells,'VariableNames',[ ...
            {'Algorithm','Function','Dimension','Seed','RunKey'},traceNames]);
        traceBlock.Algorithm=string(traceBlock.Algorithm); traceBlock.RunKey=string(traceBlock.RunKey);
        validDims=dimData(~cellfun(@isempty,dimData));
        if isempty(validDims), dimsBlock=table(); else, dimsBlock=vertcat(validDims{:}); end
        replaceKeys=string(keys(pending));
        if ~isempty(newRows), newRows(ismember(newRows.RunKey,replaceKeys),:)=[]; end
        if ~isempty(traceRows), traceRows(ismember(traceRows.RunKey,replaceKeys),:)=[]; end
        if ~isempty(dimRows), dimRows(ismember(dimRows.RunKey,replaceKeys),:)=[]; end
        if isempty(newRows), newRows=block; else, newRows=[newRows;block]; end %#ok<AGROW>
        if isempty(traceRows), traceRows=traceBlock; else, traceRows=[traceRows;traceBlock]; end %#ok<AGROW>
        if ~isempty(dimsBlock)
            if isempty(dimRows), dimRows=dimsBlock; else, dimRows=[dimRows;dimsBlock]; end %#ok<AGROW>
        end
        merged=[base;newRows];
        writetable(newRows,rawCsv); writetable(merged,mergedCsv);
        writetable(traceRows,traceCsv); writetable(dimRows,dimCsv);
        save(fullfile(outputDir,'FAD_checkpoint.mat'),'base','newRows','merged','traceRows','dimRows','seeds');
        fprintf('Checkpoint: F%d D=%d; B5 completed %d/%d, reused B0-B4 rows=%d.\n', ...
            fun,dim,height(newRows),totalExpected,height(base));
    end
end
results=merged;
end

function base=load_fad_baselines(root,seeds)
old=readtable(fullfile(root,'results','cec2022_apl_v2_6worker_dev','cec2022_development.csv'),'TextType','string');
s1=readtable(fullfile(root,'results','cec2022_stage1_missing_6worker','A0_A5_merged.csv'),'TextType','string');
s2=readtable(fullfile(root,'results','cec2022_stage2_combo_6worker','A0_A7_merged.csv'),'TextType','string');
b0=map_legacy(old(old.Variant=="gwo",:),'B0_GWO',seeds);
b1=map_legacy(old(old.Variant=="apl_weighted",:),'B1_APLweighted',seeds);
b2=map_stage(s1(s1.Algorithm=="A2_DLM2",:),'B2_APL_DLM2',seeds);
b3=map_stage(s1(s1.Algorithm=="A4_BDL50",:),'B3_APL_BDL50',seeds);
b4=map_stage(s2(s2.Algorithm=="A7_DLM2_BDL50",:),'B4_APL_DLM2_BDL50',seeds);
base=[b0;b1;b2;b3;b4];
for name=unique(base.Algorithm)'
    rows=base(base.Algorithm==name,:);
    if height(rows)~=240 || any(rows.Status~="OK")
        error('Reusable baseline %s is incomplete.',name);
    end
    expected=zeros(height(rows),1); expected(rows.Dimension==10)=200000; expected(rows.Dimension==20)=1000000;
    if any(rows.FEs~=expected) || ~isequal(sort(unique(rows.Seed))',seeds)
        error('Reusable baseline %s has incompatible seeds or FE counts.',name);
    end
end
end

function out=map_legacy(src,name,seeds)
src=src(ismember(src.Seed,seeds),:);
out=base_table(src,name);
end

function out=map_stage(src,name,seeds)
src=src(ismember(src.Seed,seeds),:);
out=base_table(src,name);
end

function out=base_table(src,name)
if isempty(src), error('Missing reusable baseline %s.',name); end
n=height(src);
out=table(repmat(string(name),n,1),src.Function,src.Dimension,src.Seed, ...
    src.BestFitness,nan(n,1),nan(n,1),src.FEs,src.Generations,src.Seconds, ...
    src.Status,src.RunKey,repmat("reused",n,1), ...
    'VariableNames',{'Algorithm','Function','Dimension','Seed','BestFitness', ...
    'MeanFitness','StdFitness','FEs','Generations','Seconds','Status','RunKey','Source'});
diagNames={'MeanFinalState','MaxFinalState','MeanK','DLMSelectedMean','APLGatePassRate', ...
    'Pattern3Evaluations','Pattern4Evaluations','Pattern5Evaluations', ...
    'Pattern3Successes','Pattern4Successes','Pattern5Successes','DLM1Attempts', ...
    'DLM1Successes','DLM1SuccessRate','DLM2Attempts','DLM2Successes', ...
    'DLM2SuccessRate','FallbackCount','DimensionMemoryUpdates'};
for k=1:numel(diagNames), out.(diagNames{k})=nan(n,1); end
end
