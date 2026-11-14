# GWO 改进项目阶段总结

**工作区：** 本项目目录（GitHub 仓库根目录）  
**目标：** 以 CEC2022 开发筛选为基础，逐步形成有消融、有应用验证的改进 GWO 论文方案。  
**状态：** APLPSO 迁移、DLM/BDL/PTL-P 单机制、DLM-2+BDL 组合、FAD-GWO/FAD-1 筛选和 FCLC-GWO Stage-1 机制筛选均已完成；新实验复用种子 41–50，旧结果保留。FAD 与 FCLC 是两条独立研究分支。

## 1. 已整理的文献来源

项目起点是本地同级 `article/` 文献库中的六篇论文：APLPSO、PTLSO、EDGWO、DLMDGWO、GDEGWO、IHS-GWO。该个人文献库不包含在本仓库中。

CEC2022 函数包从组织者仓库取得，原文件与输入数据放在 `data/CEC2022_reference/`，来源与 SHA-256 记录于 `data/SOURCE.md`。

## 2. 当前实现

旧版核心入口为 `code/gwo_optimize.m`，包含四种历史版本：

1. `gwo`：标准三领导狼 GWO。
2. `tournament`：固定三引导位置；α 保持当前最优狼，β/δ 从优于当前狼的个体中以 `[2,4]` 两种锦标赛规模抽取。
3. `adaptive`：使用排序后的前 3、4、5 只狼构造候选；先试较小集合，找到改进就接受，否则选择已评价候选中最好的一个。
4. `combined`：用双锦标赛构造 3/4/5 只领导狼的前缀候选。

所有初始化与候选评价都计入 FE；边界使用裁剪；返回值保留全程 best-so-far。Adaptive 版本最多每只狼额外评价三个候选，因而以相同总 FE 比较，而不是相同迭代数。

为保留旧实现与旧结果，APLPSO 迁移版放在独立的 `code/gwo_optimize_apl.m`，没有覆盖 `code/gwo_optimize.m`。新版本为 `apl_v2`、`apl_weighted`、`tournament_apl_v2`、`tournament_apl_weighted`；baseline 和 tournament 用 `code/gwo_optimize_instrumented.m`，它只增加种群多样性轨迹、不改变旧更新规则。

FAD-GWO 第一版放在 `code/gwo_optimize_fad.m`，由 `code/run_fad_cec2022_dev.m` 运行 B5；B0–B4 从旧实验表复用。该入口也支持 `FAD1`，仅关闭个体级 GWO 回退、保留整代 FE 推进兜底，并只运行新 B6；B0–B5 从旧表复用。FAD-1 另存独立结果目录。分析入口分别为 `code/analyze_fad_cec2022.m` 和 `code/analyze_fad1_cec2022.m`。

FCLC-GWO 是新建的独立算法分支，核心代码为 `code/gwo_optimize_fclc.m`，runner 和分析入口为 `code/run_fclc_stage1_dev.m`、`code/analyze_fclc_stage1.m`。Stage-1 只测试稀疏反事实 leader-channel credit 与权重；不包含 FAD、APL、DLM 或 BDL。

根据 APLPSO 原文核对：先随机抽取 5 个不同学习对象并按适应度排序；仅当五个对象都优于当前个体时进入 APL；`c1=1`，`cj=1/(j−1)−(FE/FEmax)/(j+1)`（j=2…5）；按 3、4、5 个对象依次提案，先改进就停止，否则从已评价候选档案中选最好的一个。加权 GWO 采用归一化的 `cj` 组合各领导狼的 GWO 提案，这是迁移设计，不是 APLPSO 原公式。APLPSO PDF 位于本地 `article/` 文献库，未纳入本仓库。

运行与分析入口：

- `run_cec2022_development.m`：并行开发筛选，默认 6 workers。
- `analyze_cec2022_development.m`：逐函数误差、平均排名、Friedman 诊断及配对 Wilcoxon/Holm 汇总。
- `run_cec2022_pilot_6worker.m`：F1、10 维的小预算接口试跑，结果与基准筛选分开保存。
- `run_cec2022_tournament_confirmation.m`：新种子确认入口。用户要求暂停后，该任务只完成 F1、10 维的 60 条运行记录，未继续其他函数或维度。
- `run_cec2022_apl_v2_development.m` / `analyze_cec2022_apl_v2.m`：六版本 APL 迁移筛选及 rank-sum 分析；新结果有独立目录。
- `gwo_optimize_apl.m`：APL-v2/weighted 两个原型及其与 Tournament 的组合；`gwo_optimize.m` 保留旧实现。
- `run_fad_cec2022_dev.m`：运行原 FAD B5 或无个体级回退的 FAD-1 B6；按 RunKey 跳过已完成记录。
- `analyze_fad1_cec2022.m`：FAD-1 与 B0–B5 的配对统计、Holm 校正、收敛/多样性轨迹和诊断汇总。
- `gwo_optimize_fclc.m`：Stage-1 的 FCLC/GCLC/固定权重实现；FAD 入口与结果保持独立。
- `run_fclc_stage1_dev.m` / `analyze_fclc_stage1.m`：FCLC、GCLC、固定权重和 GWO 的 6-worker 小规模机制筛选与分析。

## 3. 已完成的计算

### 第一轮开发筛选（旧迁移版）

- CEC2022 全部 12 个函数，D=10 和 D=20。
- 10 个开发种子；四种算法版本；MATLAB R2025b 本地 6-worker Processes 池。
- 预算为 D=10 时 200,000 FEs，D=20 时 1,000,000 FEs。
- **960/960 runs 完成，0 个失败，0 个 FE 超预算。** 合计 576,000,000 次目标函数评价。
- 结果目录：`results/cec2022_6worker_dev/`。

逐函数及统计文件：

- `cec2022_development.csv` / `.mat`：原始运行记录。
- `cec2022_per_function_summary.csv`：各函数、维度的残差误差均值/中位数/标准差与排名。
- `cec2022_algorithm_summary.csv`：汇总平均排名与最佳均值计数。
- `cec2022_pairwise_wilcoxon_holm.csv`：成对比较及 Holm 校正结果。
- `DEVELOPMENT_REPORT.md`：本轮协议、结果及限制。

### 部分确认批次

用户要求“先别跑”时，新种子确认任务已启动并完成 F1、D=10 的 60 条运行（种子 11–40，标准 GWO 与锦标赛版各 30 次）。文件保存在 `results/cec2022_tournament_confirmation_6worker/`。因为只覆盖一个函数/维度，**不用于确认整套基准的算法优劣**；该任务现已停止。

## 4. 首轮结果说明

按 24 个函数/维度对的平均残差误差排名（越低越好）：

| 版本 | 平均排名 | 最佳均值的函数/维度数 |
|---|---:|---:|
| Tournament | 1.500 | 14/24 |
| Combined | 1.875 | 9/24 |
| GWO | 3.292 | 1/24 |
| Adaptive | 3.333 | 0/24 |

配对 10 种子 Wilcoxon 检验在每个对比的 24 项设置内作 Holm 校正后：Tournament 对 GWO 有 5/24 项显著；Adaptive 对 GWO 有 1/24 项显著；Combined 对 Tournament 有 1/24 项显著。

这轮旧 `adaptive` 是“全局排名前五 + 3/4/5 等权 GWO 候选”的简化迁移，缺少 APLPSO 的随机五对象与全员优于门控，也缺少动态 (c_j)。所以它不能用于否定 APLPSO 思想。旧结论只保留为历史记录。

### 第二轮开发筛选（APLPSO 正确迁移版）

- CEC2022 全 12 函数、D=10/20、10 个新种子 41–50、6 个版本、6 worker。
- **1440/1440 runs 完成，0 失败，0 FE 不匹配**；目录为 `results/cec2022_apl_v2_6worker_dev/`。
- 合计 864,000,000 次目标函数评价；全程每个函数/维度块 checkpoint。
- 平均函数排名：APL weighted 1.750；APL v2 2.208；Tournament+APL weighted 3.000；Tournament+APL v2 3.333；Tournament 4.833；GWO 5.875。
- 每设置 10 次运行，使用未校正 Wilcoxon rank-sum 检验（遵照用户要求，不做 Holm）；APL v2 对 GWO 在 23/24 设置 p<.05，对 Tournament 在 22/24 设置 p<.05。APL weighted 对等权 APL 只有 1/24 设置 p<.05；Tournament+APL 两版整体弱于各自 APL-only 版本。
- 随机五狼门控平均通过率约 16.7%，锦标赛候选门控约 41.5%；结果和诊断详见 `results/cec2022_apl_v2_6worker_dev/APL_V2_REPORT.md`。

第二轮筛选支持继续研究 APL-GWO；动态加权暂时只是较优排名候选，尚未证明显著优于等权 APL；Tournament 与 APL 的直接组合暂不保留为主设计。

### 第三轮分阶段筛选（A0–A5、A6–A7）

- A0（APL-weighted）复用第二轮的 240 条原始运行；A1–A5（DLM-1、DLM-2、BDL-rank、BDL-50%、PTL-P）只补跑 1200 条，全部 seeds 仍为 41–50。
- 随后只补跑两个组合：A6 = APL + DLM-2 + BDL-rank；A7 = APL + DLM-2 + BDL-50%。A0–A5 继续复用；A6/A7 新跑 480 条，全部成功。
- A0–A7 合并表共 1920 行，没有新种子。A0–A5 报告在 `results/cec2022_stage1_missing_6worker/STAGE1_A0_A5_REPORT.md`；A0–A7 报告在 `results/cec2022_stage2_combo_6worker/STAGE2_A0_A7_REPORT.md`。
- A2（DLM-2）在单机制阶段平均排名最好；组合阶段 A7（DLM-2+固定50% BDL）最佳均值设置较多，但与 A6 排名并列，配对 Holm 检验未显著区分两种组合。它是候选，不是已确认的最终算法。

### FAD-GWO 双层反馈首轮筛选

- B0–B4 复用现有 seeds 41–50 数据；只新增 B5 FAD-GWO 的 240 次运行，全部 `OK`，FE 精确到 MaxFES。合并表为 1440 行。
- FAD 平均排名 3.458；低于 APL+DLM-2（2.417）和 APL+DLM-2+BDL-50（2.208），但高于 GWO（6.000）。
- FAD 对 GWO 在 20/24 项经 Holm 校正后显著；对 APL+DLM-2 和 APL+DLM-2+BDL-50 分别在 7/24 项显著，方向多数支持较简单基线。
- 门控通过率约16.7%，但门控失败回退的 GWO 更新消耗约45%的 FE 预算，是当前实现需要单独消融的行为。
- 完整报告在 `results/fad_gwo_6worker_dev/FAD_REPORT.md`；逐维信用记忆与多样性诊断在对应 CSV。

### FAD-1 个体级回退消融

- 只关闭 APL 门控失败后的个体级 GWO 回退；APL、DLM、自适应维度反馈、恢复项及候选档案规则不变。原 FAD-0 的默认行为与旧结果保留；FAD-1 另存于 `results/fad1_no_individual_fallback_6worker_dev/`。
- B0–B5 复用 seeds 41–50；新增 B6 运行 240 次，全部 `OK`，唯一 RunKey，FE 与 MaxFES 完全一致。没有新种子。
- 七个版本按 24 个函数/维度设置计算的平均排名：B6 FAD-1 为 **1.667**，B4 为 2.958，B2 为 3.250，B5 FAD-0 为 4.333，B0 GWO 为 7.000。FAD-1 在 14/24 项取得最佳均值。
- FAD-1 对 FAD-0 的配对结果为 199 胜、41 负；按对比内 24 项 Holm 校正后，14 项显著且都支持 FAD-1。对 B4 为 178 胜、62 负，5/24 项显著且均支持 FAD-1。FAD-1 相对 FAD-0、B4 的跨设置中位误差改善率分别为 30.56%、11.04%。
- FAD-1 的个体级与整代兜底计数在 240 次运行中均为 0。旧 FAD-0 的历史计数未区分两类回退；其 `FallbackCount` 总量约占 FE 的 45.69%，只能作为合并统计。
- 收敛与配对分析见 `results/fad1_no_individual_fallback_6worker_dev/FAD1_REPORT.md`。FAD-0 未保存 best-so-far 收敛曲线，本轮没有重跑 FAD-0；其最终误差和多样性轨迹可复用。

### FCLC-GWO Stage-1 独立分支

- 机制定义与 RL-LGWO、DLGWO 的公式对照见 `docs/FCLC_FORMULA_COMPARISON.md`。对照发现 RL-LGWO 已有 follower-specific 的两种离散 leader-influence 选择；DLGWO 已有以适应度测试坐标级 leader 替换的共享 exemplar。FCLC 的窄主张是同一随机提案下的稀疏、逐 follower、整向量 leave-one-leader-out 条件删除值。
- Stage-1 使用 Sphere、Rastrigin、Rosenbrock、Ackley（D=30）及 CEC2022 F1/F6（D=10），四版本：GWO、固定 [0.6,0.3,0.1] 权重、GCLC 全局信用、FCLC 个体信用。种子 41–50，N=30，六 MATLAB worker。
- 新增 220/220 次运行全部成功；匹配复用 20 条 CEC GWO 结果，合并 240 行；所有 FEs 均匹配 MaxFEs。
- 平均排名：固定权重 1.750、GWO 2.333、FCLC 2.583、GCLC 3.333。未校正 rank-sum 对比中，FCLC 对 GWO 有 2/6 项 p<.05（方向一胜一负），对固定权重 2/6 项显著且均不利于 FCLC，对 GCLC 1/6 项显著并支持 FCLC。
- FCLC 平均额外探测约占 MaxFEs 的 9.08%；终止 credit 派生权重（下一步角色重置前）的 follower 离散度约 0.0078，角色权重总体接近等权；1% FE 轨迹记录运行中实际应用的权重。该筛选尚未支持 FCLC 优于标准 GWO 或简单固定权重，暂不组合 DLM/APL。
- 详见 `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT.md`、逐次结果 CSV、信用/权重诊断和 1% FE 轨迹。当前种子筛选不是独立确认。

## 5. 实验边界

- 开发筛选用了 10 个种子，不等于正式的 30 次确认实验。
- 本轮每个任务都跑到 MaxFES；未按达到误差 (10^{-8}) 提前终止，所以不要把它报成官方 CEC 比赛终止评分。
- 仅验证通用数值优化基准，尚无应用验证。
- FAD 已使用自适应 Laplace 和差分方向，但其相对简单 APL/DLM/BDL 基线的收益尚不充分。
- `Biomimetics` 目标需要单独说明与仿生学/仿生工程的明确关联；目前的通用 CEC 优化器结果本身不构成应用匹配证明。

## 6. 建议的下一步方法与实验

FAD-1 之后新开了 FCLC 分支，Stage-1 原型已跑完。FCLC 的权重差异与性能优势目前都不够强；下一步优先审查反事实 credit 是否有预测力及权重为何接近等权，再决定修订或暂停 FCLC。FAD-2 及后续 FAD 消融仍未启动。

更复杂的 DLM-S、参数敏感性、其他组合和 30 种子正式确认尚未运行。当前不应把开发筛选结果写成最终确认性结论。

## 7. 状态

- 当前未运行 MATLAB 进程。
- 所有 MATLAB worker/批处理目前均已结束；B5 FAD、B6 FAD-1 和 FCLC Stage-1 均已结束。没有生成新种子；FAD-2 尚未启动，FCLC 尚无 DLM/APL 组合或完整 CEC2022 筛选。
