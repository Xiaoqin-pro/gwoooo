function results = run_missing_mechanisms(outputDir,workerCount,funcs,dims)
% Run only A1-A5. Reuse A0=Apl-weighted runs for seeds 41:50.
if nargin<1 || isempty(outputDir)
    outputDir=fullfile(gwo_project_root(),'results','cec2022_stage1_missing_6worker');
end
if nargin<2 || isempty(workerCount), workerCount=6; end
if nargin<3 || isempty(funcs), funcs=1:12; end
if nargin<4 || isempty(dims), dims=[10 20]; end
codeRoot=fileparts(mfilename('fullpath'));
projectRoot=gwo_project_root();
benchRoot=fullfile(projectRoot,'data','CEC2022_reference');
basePath=fullfile(projectRoot,'results','cec2022_apl_v2_6worker_dev','cec2022_development.csv');
if ~isfile(basePath), error('Reusable A0 CSV not found: %s',basePath); end
if ~isfile(fullfile(benchRoot,'cec22_test_func.mexw64')) || ~isfolder(fullfile(benchRoot,'input_data'))
    error('CEC2022 MEX or input_data is missing.');
end
if ~isfolder(outputDir), mkdir(outputDir); end
old=readtable(basePath,'TextType','string');
a0=old(old.Variant=="apl_weighted",:);
expectedFEs=zeros(height(a0),1); expectedFEs(a0.Dimension==10)=200000; expectedFEs(a0.Dimension==20)=1000000;
if height(a0)~=240 || any(a0.Status~="OK") || any(a0.FEs~=expectedFEs) || ...
        ~isequal(sort(unique(a0.Seed))',(41:50))
    error('A0 must have 240 valid rows: seeds 41:50, all functions and both dimensions.');
end

variants={'dlm1','dlm2','bdl_rank','bdl50','ptlp'};
algorithms={'A1_DLM1','A2_DLM2','A3_BDLrank','A4_BDL50','A5_PTLP'};
rawCsv=fullfile(outputDir,'A1_A5_new_runs.csv');
mergedCsv=fullfile(outputDir,'A0_A5_merged.csv');
traceCsv=fullfile(outputDir,'A1_A5_diversity_trace_1pct.csv');
addpath(codeRoot); addpath(benchRoot);
pool=gcp('nocreate');
if isempty(pool), pool=parpool('local',workerCount);
elseif pool.NumWorkers~=workerCount
    error('Existing local pool uses %d workers; requested %d.',pool.NumWorkers,workerCount);
end
oldDir=pwd; restoreDir=onCleanup(@()cd(oldDir)); %#ok<NASGU>
cd(benchRoot);
pctRunOnAll(sprintf('cd(''%s''); addpath(''%s''); addpath(''%s'');',benchRoot,benchRoot,codeRoot));

base=normalize_a0(a0);
traceNames=arrayfun(@(k)sprintf('FEpct_%02d',k),1:100,'UniformOutput',false);
if isfile(rawCsv), newRows=readtable(rawCsv,'TextType','string'); else, newRows=table(); end
if isfile(traceCsv), traceRows=readtable(traceCsv,'TextType','string'); else, traceRows=table(); end
merged=base;
if ~isempty(newRows), merged=[base;newRows]; end
names={'Function','Dimension','Seed','Algorithm','BestFitness','MeanFitness','StdFitness', ...
    'FEs','Generations','Seconds','Status','RunKey','Pattern3Evaluations', ...
    'Pattern4Evaluations','Pattern5Evaluations','Pattern3Successes','Pattern4Successes', ...
    'Pattern5Successes','ArchiveSelections','BDLMeanK','PTLPUpdateRate','DLMCount', ...
    'DLMSuccess','DoubleDLMCount','DoubleDLMSuccess','FallbackEvaluations', ...
    'DiversityInitial','DiversityFinal','DiversityMin','DiversityRecoveryMean', ...
    'DiversityRecoveryEvents','Source'};
expectedRuns=numel(funcs)*numel(dims)*numel(seeds)*numel(variants);

for dim=dims
    if dim==10, maxFEs=200000; else, maxFEs=1000000; end
    lb=-100*ones(1,dim); ub=100*ones(1,dim);
    for fun=funcs
        nRuns=numel(seeds)*numel(variants);
        taskKeys=cell(nRuns,1);
        for q0=1:nRuns
            si0=ceil(q0/numel(variants)); vi0=mod(q0-1,numel(variants))+1;
            taskKeys{q0}=sprintf('F%02d_D%02d_S%04d_%s',fun,dim,seeds(si0),algorithms{vi0});
        end
        if isempty(newRows)
            pending=1:nRuns;
        else
            doneKeys=newRows.RunKey(newRows.Status=="OK");
            pending=find(~ismember(string(taskKeys),doneKeys));
        end
        if isempty(pending)
            fprintf('Skip completed block F%d D=%d.\n',fun,dim);
            continue;
        end
        runCells=cell(numel(pending),numel(names));
        traceCells=cell(numel(pending),105);
        parfor r=1:numel(pending)
            q=pending(r);
            seedIndex=ceil(q/numel(variants));
            vIndex=mod(q-1,numel(variants))+1;
            seed=seeds(seedIndex); variant=variants{vIndex}; algorithm=algorithms{vIndex};
            key=sprintf('F%02d_D%02d_S%04d_%s',fun,dim,seed,algorithm);
            t=tic;
            try
                objective=@(x)cec2022_objective(x,fun);
                opts=struct('PopulationSize',30,'MaxFEs',maxFEs,'Seed',seed, ...
                    'Variant',variant,'DLMFraction',0.20,'EliteCount',3, ...
                    'LaplaceMu',0.6,'LaplaceSigma',0.3);
                out=gwo_optimize_apl_stage1(objective,lb,ub,opts);
                dg=out.Diagnostics; tr=out.Trace.Diversity(:)';
                row={fun,dim,seed,algorithm,out.BestFitness,out.MeanFitness,out.StdFitness, ...
                    out.FEs,out.Generations,toc(t),'OK',key,dg.PatternEvaluations(1), ...
                    dg.PatternEvaluations(2),dg.PatternEvaluations(3), ...
                    dg.PatternSuccesses(1),dg.PatternSuccesses(2),dg.PatternSuccesses(3), ...
                    dg.ArchiveSelections,dg.BDLMeanK,dg.PTLPUpdateRate,dg.DLMCount, ...
                    dg.DLMSuccess,dg.DoubleDLMCount,dg.DoubleDLMSuccess,dg.FallbackEvaluations, ...
                    dg.DiversityInitial,dg.DiversityFinal,dg.DiversityMin,NaN,NaN,'new'};
                runCells(r,:)=row;
            traceCells(r,:)=[{fun,dim,seed,algorithm,key},num2cell(tr)];
            catch ME
                runCells(r,:)=[{fun,dim,seed,algorithm,NaN,NaN,NaN,NaN,NaN, ...
                    toc(t),ME.message,key},num2cell(nan(1,19)),{'new'}];
            traceCells(r,:)=[{fun,dim,seed,algorithm,key},num2cell(nan(1,100))];
            end
        end
        block=cell2table(runCells,'VariableNames',names);
        block.Algorithm=string(block.Algorithm); block.Status=string(block.Status);
        block.RunKey=string(block.RunKey); block.Source=string(block.Source);
        traceBlock=cell2table(traceCells,'VariableNames',[ ...
            {'Function','Dimension','Seed','Algorithm','RunKey'},traceNames]);
        traceBlock.Algorithm=string(traceBlock.Algorithm); traceBlock.RunKey=string(traceBlock.RunKey);
        replaceKeys=string(taskKeys(pending));
        if ~isempty(newRows), newRows(ismember(newRows.RunKey,replaceKeys),:)=[]; end
        if ~isempty(traceRows), traceRows(ismember(traceRows.RunKey,replaceKeys),:)=[]; end
        if isempty(newRows), newRows=block; else, newRows=[newRows;block]; end %#ok<AGROW>
        if isempty(traceRows), traceRows=traceBlock; else, traceRows=[traceRows;traceBlock]; end %#ok<AGROW>
        merged=[base;newRows];
        writetable(newRows,rawCsv); writetable(merged,mergedCsv); writetable(traceRows,traceCsv);
        save(fullfile(outputDir,'A0_A5_checkpoint.mat'),'base','newRows','merged','traceRows','seeds','variants');
        fprintf('Checkpoint: F%d D=%d; new A1-A5 %d/%d, reused A0 rows=%d.\n', ...
            fun,dim,height(newRows),expectedRuns,height(base));
    end
end
results=merged;
end

function base=normalize_a0(a0)
n=height(a0); rows=cell(n,32);
for i=1:n
    rows(i,:)={a0.Function(i),a0.Dimension(i),a0.Seed(i),'A0_APLweighted', ...
        a0.BestFitness(i),NaN,NaN,a0.FEs(i),a0.Generations(i),a0.Seconds(i), ...
        a0.Status(i),a0.RunKey(i),a0.Pattern3Evaluations(i), ...
        a0.Pattern4Evaluations(i),a0.Pattern5Evaluations(i),a0.Pattern3Successes(i), ...
        a0.Pattern4Successes(i),a0.Pattern5Successes(i),a0.ArchiveSelections(i), ...
        NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,'reused'};
end
names={'Function','Dimension','Seed','Algorithm','BestFitness','MeanFitness','StdFitness', ...
    'FEs','Generations','Seconds','Status','RunKey','Pattern3Evaluations', ...
    'Pattern4Evaluations','Pattern5Evaluations','Pattern3Successes','Pattern4Successes', ...
    'Pattern5Successes','ArchiveSelections','BDLMeanK','PTLPUpdateRate','DLMCount', ...
    'DLMSuccess','DoubleDLMCount','DoubleDLMSuccess','FallbackEvaluations', ...
    'DiversityInitial','DiversityFinal','DiversityMin','DiversityRecoveryMean', ...
    'DiversityRecoveryEvents','Source'};
base=cell2table(rows,'VariableNames',names);
base.Algorithm=string(base.Algorithm); base.Status=string(base.Status);
base.RunKey=string(base.RunKey); base.Source=string(base.Source);
end
