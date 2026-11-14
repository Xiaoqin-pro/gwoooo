function merged=run_fclc_stage1_dev(outputDir,seeds,workerCount,problems,syntheticMaxFEs,algorithms)
%RUN_FCLC_STAGE1_DEV Screen FCLC/GCLC on synthetic and representative CEC tasks.
if nargin<1 || isempty(outputDir)
    outputDir=fullfile(gwo_project_root(),'results','fclc_stage1_6worker_dev');
end
if nargin<2 || isempty(seeds), seeds=41:50; end
if nargin<3 || isempty(workerCount), workerCount=6; end
if nargin<4 || isempty(problems)
    problems=["SPHERE","RASTRIGIN","ROSENBROCK","ACKLEY","CEC2022_F1_D10","CEC2022_F6_D10"];
end
if nargin<5 || isempty(syntheticMaxFEs), syntheticMaxFEs=30000; end
if nargin<6 || isempty(algorithms), algorithms=["GWO","WGWO_STATIC","GCLC","FCLC"]; end
root=gwo_project_root(); codeRoot=fileparts(mfilename('fullpath'));
benchRoot=fullfile(root,'data','CEC2022_reference');
if ~isfolder(outputDir), mkdir(outputDir); end
hasCEC=any(startsWith(string(problems),"CEC2022_"));
if hasCEC && ~isfile(fullfile(benchRoot,'cec22_test_func.mexw64'))
    error('CEC2022 reference MEX is missing from data/CEC2022_reference.');
end

rawCsv=fullfile(outputDir,'FCLC_stage1_new_runs.csv');
mergedCsv=fullfile(outputDir,'FCLC_stage1_merged.csv');
traceCsv=fullfile(outputDir,'FCLC_stage1_trace_1pct.csv');
weightCsv=fullfile(outputDir,'FCLC_weight_diagnostics.csv');
checkpointMat=fullfile(outputDir,'FCLC_stage1_checkpoint.mat');
runNames={'Algorithm','Problem','Function','Dimension','Seed','BestFitness', ...
    'BestPropagatedFitness','BestProbeFitness','MeanFitness','StdFitness','FEs', ...
    'MaxFEs','Generations','Seconds','Status','RunKey','Source','ProbeCount', ...
    'AlphaProbeCount','BetaProbeCount','DeltaProbeCount','MeanProbeMCAlpha', ...
    'MeanProbeMCBeta','MeanProbeMCDelta','MeanWeightAlpha','MeanWeightBeta', ...
    'MeanWeightDelta','WeightSpread'};
if isfile(rawCsv)
    newRows=readtable(rawCsv,'TextType','string');
    traceRows=read_if_present(traceCsv);
    weightRows=read_if_present(weightCsv);
else
    newRows=empty_run_table(); traceRows=table(); weightRows=table();
end
base=load_reusable_gwo(root,seeds,problems);
if ~isempty(base), base=base(:,runNames); end

tasks=make_tasks(problems,seeds,algorithms,syntheticMaxFEs);
baseKeys=string(base.RunKey);
pending=false(numel(tasks),1);
for q=1:numel(tasks)
    key=tasks(q).RunKey;
    compatible=any(newRows.RunKey==key & newRows.Status=="OK" & ...
        newRows.MaxFEs==tasks(q).MaxFEs);
    pending(q)=~compatible && ~any(baseKeys==key);
end
pending=find(pending);
totalExpected=numel(tasks);

if isempty(pending)
    fprintf('All requested FCLC Stage-1 RunKeys are already complete.\n');
    merged=[base;newRows];
    writetable(merged,mergedCsv);
    return;
end

addpath(codeRoot);
if hasCEC, addpath(benchRoot); end
pool=gcp('nocreate');
if isempty(pool), pool=parpool('local',workerCount);
elseif pool.NumWorkers~=workerCount
    error('Existing pool uses %d workers; requested %d.',pool.NumWorkers,workerCount);
end
oldDir=pwd; restoreDir=onCleanup(@()cd(oldDir)); %#ok<NASGU>
if hasCEC
    cd(benchRoot);
    pctRunOnAll(sprintf('cd(''%s''); addpath(''%s''); addpath(''%s'');', ...
        benchRoot,benchRoot,codeRoot));
end

runCells=cell(numel(pending),numel(runNames));
traceCells=cell(numel(pending),1); weightCells=cell(numel(pending),1);
parfor q=1:numel(pending)
    task=tasks(pending(q)); t=tic;
    try
        objective=objective_for(task.Problem,task.Function);
        if task.Algorithm=="GWO"
            opts=struct('PopulationSize',30,'MaxFEs',task.MaxFEs,'Seed',task.Seed,'Variant','gwo');
            out=gwo_optimize(objective,task.LowerBound,task.UpperBound,opts);
            dg=empty_diagnostics();
            trace=standard_trace(out,task);
        else
            mode=algorithm_mode(task.Algorithm);
            opts=struct('PopulationSize',30,'MaxFEs',task.MaxFEs,'Seed',task.Seed, ...
                'Mode',mode,'ProbeFraction',0.10,'CreditLearningRate',0.20, ...
                'SoftmaxTemperature',1.0,'MinWeight',0.05,'FixedWeights',[0.6 0.3 0.1]);
            out=gwo_optimize_fclc(objective,task.LowerBound,task.UpperBound,opts);
            dg=out.Diagnostics;
            trace=fclc_trace(out,task);
        end
        if task.Algorithm=="GWO"
            bestProp=out.BestFitness; bestProbe=NaN; meanFit=NaN; stdFit=NaN;
            fcount=NaN(1,3); meanMC=nan(1,3); meanW=nan(1,3); spread=NaN;
        else
            bestProp=out.BestPropagatedFitness; bestProbe=out.BestProbeFitness;
            if ~isfinite(bestProbe), bestProbe=NaN; end
            meanFit=out.MeanFitness; stdFit=out.StdFitness;
            fcount=dg.ProbeCountByRole; meanMC=dg.MeanProbeContribution;
            meanW=dg.MeanFinalWeight; spread=dg.FinalWeightSpread;
        end
        values={char(task.Algorithm),char(task.Problem),task.Function,task.Dimension, ...
            task.Seed,out.BestFitness,bestProp,bestProbe,meanFit,stdFit,out.FEs, ...
            task.MaxFEs,out.Generations,toc(t),'OK',char(task.RunKey),'new', ...
            dg.ProbeCount,fcount(1),fcount(2),fcount(3),meanMC(1),meanMC(2), ...
            meanMC(3),meanW(1),meanW(2),meanW(3),spread};
        runCells(q,:)=values;
        traceCells{q}=trace;
        if task.Algorithm=="GWO"
            weightCells{q}=table();
        else
            weightCells{q}=weight_table(out.Diagnostics,task);
        end
    catch ME
        values={char(task.Algorithm),char(task.Problem),task.Function,task.Dimension, ...
            task.Seed,NaN,NaN,NaN,NaN,NaN,NaN,task.MaxFEs,NaN,toc(t), ...
            char(string(ME.message)),char(task.RunKey),'new',NaN,NaN,NaN,NaN, ...
            NaN,NaN,NaN,NaN,NaN,NaN,NaN};
        runCells(q,:)=values;
        traceCells{q}=table(); weightCells{q}=table();
    end
end

block=cell2table(runCells,'VariableNames',runNames);
block.Algorithm=string(block.Algorithm); block.Problem=string(block.Problem);
block.Status=string(block.Status); block.RunKey=string(block.RunKey); block.Source=string(block.Source);
traces=traceCells(~cellfun(@isempty,traceCells));
if isempty(traces), traceBlock=table(); else, traceBlock=vertcat(traces{:}); end
weights=weightCells(~cellfun(@isempty,weightCells));
if isempty(weights), weightBlock=table(); else, weightBlock=vertcat(weights{:}); end
if ~isempty(newRows), newRows=newRows(~ismember(string(newRows.RunKey),string(tasks(pending).RunKey)),:); end
if isempty(newRows), newRows=block; else, newRows=[newRows;block]; end
if ~isempty(traceBlock)
    if isempty(traceRows), traceRows=traceBlock; else, traceRows=[traceRows;traceBlock]; end
end
if ~isempty(weightBlock)
    if isempty(weightRows), weightRows=weightBlock; else, weightRows=[weightRows;weightBlock]; end
end
merged=[base;newRows];
writetable(newRows,rawCsv); writetable(merged,mergedCsv);
writetable(traceRows,traceCsv); writetable(weightRows,weightCsv);
save(checkpointMat,'base','newRows','merged','traceRows','weightRows','seeds','problems','algorithms');
fprintf('FCLC Stage-1 checkpoint: %d/%d rows; new OK=%d, new non-OK=%d, reused GWO=%d.\n', ...
    height(newRows)+height(base),totalExpected,sum(newRows.Status=="OK"), ...
    sum(newRows.Status~="OK"),height(base));
end

function T=empty_run_table()
names={'Algorithm','Problem','Function','Dimension','Seed','BestFitness', ...
    'BestPropagatedFitness','BestProbeFitness','MeanFitness','StdFitness','FEs', ...
    'MaxFEs','Generations','Seconds','Status','RunKey','Source','ProbeCount', ...
    'AlphaProbeCount','BetaProbeCount','DeltaProbeCount','MeanProbeMCAlpha', ...
    'MeanProbeMCBeta','MeanProbeMCDelta','MeanWeightAlpha','MeanWeightBeta', ...
    'MeanWeightDelta','WeightSpread'};
types={'string','string','double','double','double','double','double','double', ...
    'double','double','double','double','double','double','string','string','string', ...
    'double','double','double','double','double','double','double','double','double', ...
    'double','double'};
T=table('Size',[0 numel(names)],'VariableTypes',types,'VariableNames',names);
end

function d=empty_diagnostics()
d=struct('ProbeCount',NaN,'ProbeCountByRole',nan(1,3), ...
    'MeanProbeContribution',nan(1,3),'FinalFollowerWeights',nan(0,3), ...
    'FinalCredit',nan(0,3),'FinalGlobalCredit',nan(1,3), ...
    'FinalOmegaMask',false(0,1),'MeanFinalWeight',nan(1,3), ...
    'FinalWeightSpread',NaN);
end

function T=read_if_present(path)
if isfile(path), T=readtable(path,'TextType','string'); else, T=table(); end
end

function tasks=make_tasks(problems,seeds,algorithms,syntheticMaxFEs)
tasks=struct('Algorithm',{},'Problem',{},'Function',{},'Dimension',{},'Seed',{}, ...
    'MaxFEs',{},'Optimum',{},'LowerBound',{},'UpperBound',{},'RunKey',{});
for p=string(problems)
    [D,lb,ub,maxFEs,fid,optimum]=problem_config(p,syntheticMaxFEs);
    for alg=string(algorithms)
        for seed=seeds
            key=sprintf('FCLC_%s_D%02d_S%04d_%s',char(p),D,seed,char(alg));
            tasks(end+1)=struct('Algorithm',alg,'Problem',p,'Function',fid, ...
                'Dimension',D,'Seed',seed,'MaxFEs',maxFEs,'Optimum',optimum, ...
                'LowerBound',lb,'UpperBound',ub,'RunKey',string(key)); %#ok<AGROW>
        end
    end
end
end

function [D,lb,ub,maxFEs,fid,optimum]=problem_config(problem,syntheticMaxFEs)
fid=NaN; optimum=0;
switch upper(problem)
    case "SPHERE", D=30; lb=-100*ones(1,D); ub=100*ones(1,D); maxFEs=syntheticMaxFEs;
    case "RASTRIGIN", D=30; lb=-5.12*ones(1,D); ub=5.12*ones(1,D); maxFEs=syntheticMaxFEs;
    case "ROSENBROCK", D=30; lb=-30*ones(1,D); ub=30*ones(1,D); maxFEs=syntheticMaxFEs;
    case "ACKLEY", D=30; lb=-32.768*ones(1,D); ub=32.768*ones(1,D); maxFEs=syntheticMaxFEs;
    case "CEC2022_F1_D10", D=10; lb=-100*ones(1,D); ub=100*ones(1,D); maxFEs=200000; fid=1; optimum=300;
    case "CEC2022_F6_D10", D=10; lb=-100*ones(1,D); ub=100*ones(1,D); maxFEs=200000; fid=6; optimum=1800;
    otherwise, error('Unknown Stage-1 problem: %s.',problem);
end
end

function base=load_reusable_gwo(root,seeds,problems)
base=empty_run_table();
hasCEC=any(startsWith(string(problems),"CEC2022_"));
if ~hasCEC, return; end
src=readtable(fullfile(root,'results','cec2022_apl_v2_6worker_dev', ...
    'cec2022_development.csv'),'TextType','string');
for p=string(problems)
    [D,~,~,maxFEs,fid,~]=problem_config(p,30000);
    if isnan(fid), continue; end
    rows=src(src.Variant=="gwo" & src.Function==fid & src.Dimension==D & ...
        ismember(src.Seed,seeds),:);
    if height(rows)~=numel(seeds) || any(rows.Status~="OK") || any(rows.FEs~=maxFEs)
        error('Reusable GWO baseline for %s is incomplete or uses incompatible settings.',p);
    end
    values=cell(height(rows),28);
    for j=1:height(rows)
        runKey=sprintf('FCLC_%s_D%02d_S%04d_GWO',char(p),D,rows.Seed(j));
        values(j,:)={'GWO',char(p),fid,D,rows.Seed(j),rows.BestFitness(j), ...
            rows.BestFitness(j),NaN,NaN,NaN,rows.FEs(j),maxFEs,rows.Generations(j), ...
            rows.Seconds(j),'OK',runKey,'reused',NaN,NaN,NaN,NaN,NaN,NaN,NaN, ...
            NaN,NaN,NaN,NaN};
    end
    block=cell2table(values,'VariableNames',base.Properties.VariableNames);
    block.Algorithm=string(block.Algorithm); block.Problem=string(block.Problem);
    block.Status=string(block.Status); block.RunKey=string(block.RunKey); block.Source=string(block.Source);
    base=[base;block]; %#ok<AGROW>
end
end

function mode=algorithm_mode(algorithm)
switch algorithm
    case "WGWO_STATIC", mode='static';
    case "GCLC", mode='gclc';
    case "FCLC", mode='fclc';
    otherwise, error('Unknown FCLC Stage-1 algorithm %s.',algorithm);
end
end

function objective=objective_for(problem,functionId)
switch upper(problem)
    case "SPHERE", objective=@sphere_obj;
    case "RASTRIGIN", objective=@rastrigin_obj;
    case "ROSENBROCK", objective=@rosenbrock_obj;
    case "ACKLEY", objective=@ackley_obj;
    otherwise, objective=@(x)cec2022_objective(x,functionId);
end
end

function v=sphere_obj(x), v=sum(x.^2); end
function v=rastrigin_obj(x), v=10*numel(x)+sum(x.^2-10*cos(2*pi*x)); end
function v=rosenbrock_obj(x), v=sum(100*(x(2:end)-x(1:end-1).^2).^2+(1-x(1:end-1)).^2); end
function v=ackley_obj(x)
d=numel(x); v=-20*exp(-0.2*sqrt(sum(x.^2)/d))-exp(sum(cos(2*pi*x))/d)+20+exp(1);
end

function T=standard_trace(out,task)
target=ceil((1:100)'*task.MaxFEs/100);
traceFEs=out.Trace.FEs(:); traceBest=out.Trace.BestFitness(:);
vals=nan(100,1);
for k=1:100
    q=find(traceFEs>=target(k),1,'first');
    if isempty(q), q=numel(traceFEs); end
    vals(k)=traceBest(q);
end
T=trace_table(task,vals,vals,nan(100,3),nan(100,1),zeros(100,1));
end

function T=fclc_trace(out,task)
T=trace_table(task,out.Trace.BestFitness(:),out.Trace.BestPropagatedFitness(:), ...
    out.Trace.MeanWeights,out.Trace.WeightSpread(:),out.Trace.ProbeCount(:));
end

function T=trace_table(task,best,propagated,meanWeights,weightSpread,probeCount)
n=100;
T=table(repmat(task.Algorithm,n,1),repmat(task.Problem,n,1), ...
    repmat(task.Function,n,1),repmat(task.Dimension,n,1),repmat(task.Seed,n,1), ...
    (1:n)',best(:),propagated(:),meanWeights(:,1),meanWeights(:,2),meanWeights(:,3), ...
    weightSpread(:),probeCount(:),'VariableNames',{'Algorithm','Problem','Function', ...
    'Dimension','Seed','FEPercent','BestEvaluated','BestPropagated','MeanWeightAlpha', ...
    'MeanWeightBeta','MeanWeightDelta','WeightSpread','ProbesThisGeneration'});
end

function T=weight_table(dg,task)
ids=find(dg.FinalOmegaMask); n=numel(ids); roles=["alpha","beta","delta"];
alg=task.Algorithm; problem=task.Problem;
follower=repelem(ids(:),3); role=repmat(roles(:),n,1);
w=reshape(dg.FinalFollowerWeights(ids,:)',[],1);
if strcmp(dg.Mode,'gclc'), c=repmat(dg.FinalGlobalCredit(:),n,1);
else, c=reshape(dg.FinalCredit(ids,:)',[],1); end
T=table(repmat(alg,3*n,1),repmat(problem,3*n,1),repmat(task.Seed,3*n,1), ...
    follower,role,w,c,'VariableNames',{'Algorithm','Problem','Seed','FollowerID', ...
    'LeaderRole','FinalWeight','FinalCredit'});
end
