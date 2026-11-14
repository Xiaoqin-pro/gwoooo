function results=run_stage2_combinations(outputDir,workerCount)
% Run only DLM2+BDL-rank and DLM2+BDL50; merge reused A0-A5 rows.
if nargin<1 || isempty(outputDir)
    outputDir=fullfile(gwo_project_root(),'results','cec2022_stage2_combo_6worker');
end
if nargin<2 || isempty(workerCount), workerCount=6; end
codeRoot=fileparts(mfilename('fullpath'));
projectRoot=gwo_project_root();
benchRoot=fullfile(projectRoot,'data','CEC2022_reference');
stage1Dir=fullfile(projectRoot,'results','cec2022_stage1_missing_6worker');
stage1Csv=fullfile(stage1Dir,'A0_A5_merged.csv');
if ~isfile(stage1Csv), error('A0-A5 merged stage-1 file missing.'); end
if ~isfile(fullfile(benchRoot,'cec22_test_func.mexw64')) || ~isfolder(fullfile(benchRoot,'input_data'))
    error('CEC2022 MEX or input_data is missing.');
end
if ~isfolder(outputDir), mkdir(outputDir); end
base=readtable(stage1Csv,'TextType','string');
need=["A0_APLweighted","A1_DLM1","A2_DLM2","A3_BDLrank","A4_BDL50","A5_PTLP"];
for j=1:numel(need)
    rows=base(base.Algorithm==need(j),:);
    if height(rows)~=240 || any(rows.Status~="OK")
        error('Stage-1 baseline %s is incomplete.',need(j));
    end
end
variants={'dlm2_bdl_rank','dlm2_bdl50'};
algorithms={'A6_DLM2_BDLrank','A7_DLM2_BDL50'};
seeds=41:50; funcs=1:12; dims=[10 20];
rawCsv=fullfile(outputDir,'A6_A7_new_runs.csv');
mergedCsv=fullfile(outputDir,'A0_A7_merged.csv');
traceCsv=fullfile(outputDir,'A6_A7_diversity_trace_1pct.csv');
if isfile(rawCsv), error('Stage-2 output already exists; refusing to overwrite.'); end
addpath(codeRoot); addpath(benchRoot);
pool=gcp('nocreate');
if isempty(pool), pool=parpool('local',workerCount);
elseif pool.NumWorkers~=workerCount
    error('Existing local pool uses %d workers; requested %d.',pool.NumWorkers,workerCount);
end
oldDir=pwd; restoreDir=onCleanup(@()cd(oldDir)); %#ok<NASGU>
cd(benchRoot);
pctRunOnAll(sprintf('cd(''%s''); addpath(''%s''); addpath(''%s'');',benchRoot,benchRoot,codeRoot));

newRows=table(); traceRows=table();
traceNames=arrayfun(@(k)sprintf('FEpct_%02d',k),1:100,'UniformOutput',false);
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
        rows=cell(nRuns,numel(names)); traces=cell(nRuns,105);
        parfor q=1:nRuns
            si=ceil(q/numel(variants)); vi=mod(q-1,numel(variants))+1;
            seed=seeds(si); variant=variants{vi}; algorithm=algorithms{vi};
            key=sprintf('F%02d_D%02d_S%04d_%s',fun,dim,seed,algorithm);
            t=tic;
            try
                objective=@(x)cec2022_objective(x,fun);
                opts=struct('PopulationSize',30,'MaxFEs',maxFEs,'Seed',seed, ...
                    'Variant',variant,'DLMFraction',0.20,'EliteCount',3, ...
                    'LaplaceMu',0.6,'LaplaceSigma',0.3);
                out=gwo_optimize_apl_stage1(objective,lb,ub,opts); dg=out.Diagnostics;
                rows(q,:)={fun,dim,seed,algorithm,out.BestFitness,out.MeanFitness,out.StdFitness, ...
                    out.FEs,out.Generations,toc(t),'OK',key,dg.PatternEvaluations(1), ...
                    dg.PatternEvaluations(2),dg.PatternEvaluations(3), ...
                    dg.PatternSuccesses(1),dg.PatternSuccesses(2),dg.PatternSuccesses(3), ...
                    dg.ArchiveSelections,dg.BDLMeanK,dg.PTLPUpdateRate,dg.DLMCount, ...
                    dg.DLMSuccess,dg.DoubleDLMCount,dg.DoubleDLMSuccess,dg.FallbackEvaluations, ...
                    dg.DiversityInitial,dg.DiversityFinal,dg.DiversityMin, ...
                    dg.DiversityRecoveryMean,dg.DiversityRecoveryEvents,'new'};
                traces(q,:)=[{fun,dim,seed,algorithm,key},num2cell(out.Trace.Diversity(:)')];
            catch ME
                rows(q,:)=[{fun,dim,seed,algorithm,NaN,NaN,NaN,NaN,NaN,toc(t),ME.message,key}, ...
                    num2cell(nan(1,19)),{'new'}];
                traces(q,:)=[{fun,dim,seed,algorithm,key},num2cell(nan(1,100))];
            end
        end
        block=cell2table(rows,'VariableNames',names);
        block.Algorithm=string(block.Algorithm); block.Status=string(block.Status);
        block.RunKey=string(block.RunKey); block.Source=string(block.Source);
        traceBlock=cell2table(traces,'VariableNames',[{'Function','Dimension','Seed','Algorithm','RunKey'},traceNames]);
        traceBlock.Algorithm=string(traceBlock.Algorithm); traceBlock.RunKey=string(traceBlock.RunKey);
        newRows=[newRows;block]; traceRows=[traceRows;traceBlock]; %#ok<AGROW>
        merged=[base;newRows];
        writetable(newRows,rawCsv); writetable(merged,mergedCsv); writetable(traceRows,traceCsv);
        save(fullfile(outputDir,'A0_A7_checkpoint.mat'),'base','newRows','merged','traceRows','seeds','variants');
        fprintf('Checkpoint: F%d D=%d; A6-A7 %d/%d; reused A0-A5 rows=%d.\n', ...
            fun,dim,height(newRows),expectedRuns,height(base));
    end
end
results=merged;
end
