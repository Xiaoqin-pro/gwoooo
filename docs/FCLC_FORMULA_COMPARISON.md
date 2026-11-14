# FCLC-GWO 公式对照与第一阶段决策

**日期：** 2026-11-14  
**项目分支：** 新建的 FCLC-GWO 研究方向；FAD-GWO 保留为独立历史分支。  
**审查范围：** RL-LGWO、DLGWO 原文算法公式，以及当前 FCLC 草案。  
**本轮结论：** **条件性进入 FCLC 第一版原型；暂不做完整 CEC2022 大规模筛选。**

本地原文：[`RL-LGWO.pdf`](../../article/RL-LGWO.pdf)、[`DLGWO.pdf`](../../article/DLGWO.pdf)。公开来源：[RL-LGWO，Knowledge-Based Systems (2025)](https://doi.org/10.1016/j.knosys.2025.114471)、[DLGWO，Computational Intelligence and Neuroscience (2022)](https://doi.org/10.1155/2022/3603607)。

## 1. 先把创新主张收窄

FCLC 不能把“个体化领导权重”本身作为主要新意：RL-LGWO 已让不同跟随狼根据自身状态，选择领导者影响模式。FCLC 可检验的核心差异应当收窄为：

> 对每只跟随狼，使用同一组随机 GWO 提案构造“当前融合候选”和“删除一个领导通道后的反事实候选”，用配对目标函数差估计该领导通道对这只狼的**条件删除价值**，再以稀疏、平衡的探测预算更新连续权重。

这与“独立因果贡献”或 Shapley value 不等价：删除一位领导者后对剩余权重重新归一化，因此测到的是当前领导组合下的条件边际效果。论文中应使用“条件边际/删除价值”这类准确表述。

## 2. 逐公式对照

| 设计点 | RL-LGWO | DLGWO | FCLC-GWO（修订后的 Stage 1） |
|---|---|---|---|
| GWO 提案 | α、β、δ 分别生成 (Z_{i,l}=X_l-A_{i,l}|C_{i,l}X_l-X_i|) | 用 DLS 生成一个共享 exemplar (X_L)，再由 (X_L) 产生 GWO 提案 | α、β、δ 各自生成标准 GWO 提案 (Z_{i,l})，沿用标准随机系数 |
| 决策对象 | 每只非领导狼是一个 RL agent | 每代一个全体共享 exemplar | 每只 omega 跟随狼都有自己的领导通道信用记忆 (H_{i,l}) |
| 反馈信号 | 跟随狼近期适应度变化符号与当前动作；共享 Q-table | 在每一维比较以 α、β 替换 exemplar 坐标后的适应度 | 比较同一随机提案下完整融合与删除单一领导通道的目标值 |
| 领导权重/融合 | 文中给两个影响向量：((0.6,0.3,0.1)) 与 ((1/3,1/3,1/3))，每只跟随狼在四个组合动作中选择；不是连续信用权重 | 不学习权重；逐维选择 α、β、δ 提供的更优坐标，形成一个共享向量 | EMA 汇总配对删除值，再经 softmax 得到个体连续权重 (w_{i,l}) |
| 探测粒度 | 每只跟随狼更新动作；leader 另有一套更新策略 | 每维测试两个坐标替代，共约 (2D) 次额外评价/代 | 每代仅对平衡抽样的一小部分 omega 做一次反事实评价；成本随探测数增长，不随 D 线性增长 |
| 探测是否改变候选 | 动作直接决定当前跟随狼如何更新 | 被评价的 exemplar 坐标直接进入共享领导信息 | 反事实候选只用于归因；不进入种群、不替换正常 GWO 候选 |
| leader 自身更新 | α/β/δ 由另一套 RL leader-update 模块更新 | 由共享 exemplar 代替三只 leaders 来引导其他狼 | α/β/δ 继续用原始 GWO 规则更新；FCLC 只改 omega 的融合方式 |
| 与 FCLC 的关键差异 | RL 学习“选哪种预设模式”；FCLC 直接测“当前领导通道对这只 follower 的配对目标差” | DLGWO 进行全局共享、坐标级替换；FCLC 进行 follower-specific、整向量级删除对照 | — |

### 2.1 RL-LGWO 的精确机制

RL-LGWO 的标准 GWO 分量为：

\[
Z_{i,l}=X_l-A_{i,l}|C_{i,l}X_l-X_i|,\qquad
X_i^{t+1}=\frac{Z_{i,\alpha}+Z_{i,\beta}+Z_{i,\delta}}{3}.
\]

跟随狼状态包括最近三次适应度变化的符号以及上一次动作。四个 follower action 组合两种 (a) 调节曲线与两种 leader influence 模式；两个模式分别是 α 主导的 ((0.6,0.3,0.1)) 和三者等权。各 agent 共用 Q-table。

因此，FCLC 与 RL-LGWO 在“每只跟随狼自适应使用 leader influence”这一层面有明显重叠。FCLC 的可区分点只能是它用同一随机候选下的 leave-one-leader-out 配对评价，显式估计每条 leader 通道的条件删除价值，并用稀疏探测更新连续权重。

原文还有两个实现对照问题：其 Eq. (12) 显示三提案简单平均，而 action 说明又定义了 φ 权重，却未在该更新式中显示 φ；其 Eq. (17) 写成 (f(X_i^t)-f(X_i^{t-1}))，这在最小化时对改进给出负值，和“改进获得正奖励”的文字说明相反。作者引用的 RLSetGWO 仓库目前定位于集合型 influence-maximization 任务，代码采用离散集合操作与 DQN；它不能单独消除数值优化版本的这两处公式歧义。

### 2.2 DLGWO 的精确机制

DLGWO 每代只构造一个共享 exemplar。先令 (X_L=X_\delta)。对每个坐标 (j)，建立 (X^{temp1})（用 (X_{\alpha,j}) 替换 (X_{L,j})）和 (X^{temp2})（用 (X_{\beta,j}) 替换 (X_{L,j})），按

\[
X_{L,j}\leftarrow \arg\min_{v\in\{X_{L,j},X_{\alpha,j},X_{\beta,j}\}}f(X_L\text{ with coordinate }j\text{ set to }v)
\]

逐维更新 exemplar。随后所有 omega 狼以该 (X_L) 替代原来的三领导融合，并另加 Lévy flight。原文给出的 DLS 额外评价成本约为每代 (2D) 次。

这说明“用适应度比较由不同领导信息构成的候选”并非空白。FCLC 必须把差异明确限制在**对每个 follower 的整向量、成对删除评价**，而不是“评估领导候选优劣”这一宽泛说法。

## 3. FCLC 公式需要这样修正

草案以等权 (Y_i^{all}) 作为被比较对象，但一旦历史信用已产生个体权重，算法实际执行的就是加权候选。若反事实仍与等权候选比较，credit signal 与当前动作不一致。Stage 1 应冻结当前 (w_i^t)、领导位置及同一组随机系数，并定义：

\[
Y_i^t=\mathcal B\!\left(\sum_{l\in\{\alpha,\beta,\delta\}}w_{i,l}^t Z_{i,l}^t\right),
\]

\[
Y_{i,-l}^t=\mathcal B\!\left(
\frac{\sum_{k\ne l}w_{i,k}^tZ_{i,k}^t}{1-w_{i,l}^t}
\right),\qquad
MC_{i,l}^t=\operatorname{clip}\!\left(
\frac{f(Y_{i,-l}^t)-f(Y_i^t)}{s_t+\epsilon},-1,1\right),
\]

其中 ℓ ∈ {α, β, δ}，ℼ 是对两个候选完全相同的边界修复，(s_t) 在探测前由当代种群适应度计算并冻结（初版建议 (s_t=\mathrm{IQR}(F_t))）。正 (MC) 表示删除该通道并重归一化后更差，即在此组合上下文中保留该通道有帮助。

只对被探测的 ((i,l)) 更新：

\[
H_{i,l}^{t+1}=(1-\rho)H_{i,l}^t+\rho MC_{i,l}^t,\qquad
q_{i,l}=\frac{e^{H_{i,l}/T}}{\sum_k e^{H_{i,k}/T}},\qquad
w_{i,l}=w_{\min}+(1-3w_{\min})q_{i,l}.
\]

未探测的记忆保持不变；新权重从下一代开始使用。这样探测候选不会被错误地当作正常位置更新，也不会额外消耗再评一次完整候选的 FE。

### Stage 1 的实现约定

| 项目 | 第一版约定 |
|---|---|
| 更新对象 | 当前排名前三以外的 omega 跟随狼；每只狼有持久 ID |
| 领导索引 | H 的三列表示当代 α/β/δ **角色通道**，不是固定狼身份 |
| 初始信用 | (H=0)，得到等权初始 (w=1/3) |
| 首版数值常数 | ρ=0.2，T=1，w_min=0.05；作为开发原型默认值，不宣称最优 |
| IQR 参考 | 当代开始、任何当前代 proposal/probe 评价之前，对当前全种群 fitness 计算 IQR 并冻结 |
| IQR 退化处理 | 用 (s_t=\max(\mathrm{IQR}(F_t),10^{-12}\max(1,|\mathrm{median}(F_t)|)))；MC 仍 clip 到 [-1,1] |
| 探测数量 | (m=\max(1,\lceil0.1(N-3)\rceil)) 个不同 omega/代；N=30 时 m=3 |
| 探测排程 | 在 omega ID × α/β/δ 角色对中按最久未探测轮换；每代选 m 个不同 omega。权重记忆属于 recipient wolf ID，三列表示领导角色 |
| 角色转换 | 成为 alpha/beta/delta 时暂停该 wolf 的 probe；从 leader 重新成为 omega 时将其 (H_i) 重置为 0，避免复用过时 follower 信用 |
| 随机数 | 完整和 leave-one-out 候选共用完全相同的 GWO 随机系数 |
| 接受策略 | 采用仓库标准 GWO 的代际替换方式；探测候选不进入种群或精英记录 |
| FE | 初始化、正常候选、每个探测候选全部计入同一 MaxFEs；达到预算立即停止，不按迭代数对齐 |
| 其他机制 | 不含 APL、FAD、DLM、BDL、Lévy、贪婪接受或额外 leader 更新算子 |

当 (w_{i,l}) 接近 1 时，删除式的 (1-w_{i,l}) 会变小；softmax 下限和稳定的两项重归一化实现须在编码中保证数值安全。

## 4. 近期相关工作的边界

针对性检索还找到了 2026 年的 DSGWO。它用个体历史最优改善量维护 (Credit_i^t=\rho Credit_i^{t-1}+\Delta f_i^t)，再用贡献分数挑战 β/δ 领导角色。它已显示“GWO 个体贡献分数 + 遗忘”不是新的宽泛思路；但其分数归属于个体自身并驱动层级更换，不是某个 leader proposal 对特定 follower proposal 的条件删除值。因此 FCLC 只能主张 leader-to-follower channel attribution，不能主张首次在 GWO 使用贡献信用。

本轮有针对性检索暂未发现与“稀疏、同随机数、逐 follower 的整向量 leave-one-leader-out 配对评分”完全相同的实现。另有 2019 年工作专门研究 dominant-wolf 重新定位与层级影响变化；2026 年 DSGWO 用个体 pbest 改进量累计 contribution credit 并驱动 leader promotion。后者的 credit 属于搜索个体自身、用于社会角色挑战，而不是某个 leader channel 对某个 follower candidate 的条件效果。它们均不等于 FCLC 草案，但意味着“GWO leaders 重要”“个体信用记忆”不能单独作贡献声明。[Effects of dominant wolves (2019)](https://doi.org/10.1016/j.asoc.2019.105658)；[DSGWO intrusion-detection paper (2026)](https://www.mdpi.com/2079-9292/15/16/3730)。

这仍是有限查新，不是穷尽式结论。正式宣称方法新颖前，还要重点检索 GWO leader weighting、fitness-based credit assignment、counterfactual/marginal influence 与 evolutionary operator selection 的交叉研究。

## 5. 决策

### 决策：条件性进入第一版 MATLAB 原型

已核对的两篇论文没有实现与上述修订式完全相同的机制：RL-LGWO 是 follower-specific 但离散的策略/权重模式；DLGWO 是 objective-tested 但共享、逐坐标的 exemplar。因此足以支持一个**窄范围的 Stage-1 原型**，但不足以支持“首创个体化 leader weights”或完整论文的新颖性结论。

第一版只实现标准 GWO + FCLC 稀疏归因，并沿用已完成的种子编号 41–50 做机制筛选。Omega 以标准 GWO 等权候选为起点；top-3 leaders 的更新保持标准 GWO。完整候选与其 probe 共用随机 (A,C)，都按现有标准 GWO 用 clip 边界；probe 只记账、不替换种群。建议先在 Sphere、Rastrigin、Rosenbrock、Ackley 和少量旋转/混合 CEC2022 函数上验证信用是否真的形成个体差异、是否减少有害 leader channel，再决定是否扩展到完整 CEC2022。RL-LGWO 若没有与论文公式一致的数值优化参考实现，作为文献对照，不伪造同条件结果。

仅在以下证据出现后继续扩展：

1. 不同 follower 的权重分布确实存在可重复差异，而不是退化成一个全局权重向量。
2. 反事实分数能预测其后续候选的实际方向性收益。
3. 额外探测的 FE 成本在总预算内，且固定 FE 下优于等权 GWO 及简单固定权重对照。

## 6. 本轮产物与状态

- 已读完本地 RL-LGWO 与 DLGWO PDF 的方法/公式部分，并对 DLGWO 相关代价公式做了视觉核对。
- 已将公式对照、RL-LGWO 论文内公式歧义、2026 DSGWO 的相邻贡献机制和修订后的 Stage-1 定义写入本文。
- **Stage-1 已完成。** 独立算法入口为 `code/gwo_optimize_fclc.m`，runner/analysis 为 `code/run_fclc_stage1_dev.m` 与 `code/analyze_fclc_stage1.m`；FAD 代码和旧结果未改动。
- 首轮结果见 `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT.md`。本轮权重仍接近等权，FCLC 平均排名没有超过 GWO 或固定 α 主导权重；因此尚不进入 FCLC+DLM 或 FCLC+APL。
- 下一步先检查信用信号为何没有形成稳定的个体差异，再决定是否修订估计器或暂停这条算法分支。

## Stage-1 follow-up — 2026-11-14

The conditional Stage-1 decision has now been exercised as a small mechanism screen. The independent `gwo_optimize_fclc.m` implementation and six-worker runner were added without modifying the FAD code.

- 220 new runs completed successfully; 20 matching CEC2022 GWO rows for F1/F6, D=10, seeds 41–50 were reused. The merged table has 240 rows and exact FE caps.
- Across six problem settings, average ranks were fixed weights 1.750, GWO 2.333, FCLC 2.583, GCLC 3.333.
- The reported terminal stored-credit follower-weight spread for FCLC was 0.0078; it is computed after the last credit update and terminal leader re-ranking, before a possible next-generation role reset. The 1%-FE traces record weights actually applied. Learned weights remained close to equal on average. FCLC did not beat the fixed-weight or standard-GWO baselines overall.
- The result supports further diagnosis of the credit signal before considering FCLC+DLM or FCLC+APL. Those combinations have not been run.
- Detailed results are in `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT.md`.

## Implementation-audit follow-up — 2026-11-14

The silent-assumption sweep found a stale Rosenbrock-bound row and clarified the semantics that were previously implicit. The ledger now records: the linear-interpolation IQR convention; one per-generation mean-credit update per global role for GCLC; unadjusted two-sided rank-sum with the declared all-tied convention; error clipping and relative-improvement denominator; output-cache reuse/failure behavior; and terminal next-generation weight semantics.

The GWO trace exporter had filled every propagated-best checkpoint with the terminal value. This was corrected to equal the corresponding best-evaluated series for the no-probe GWO baseline, and the saved trace/checkpoints were repaired from the already stored evaluated trace. No optimization runs or final fitness/rank values changed. Stage-1 traces use the first completed generation at or above each FE checkpoint. The 300-FE smoke has some thresholds before initialization completes; those smoke traces are interface checks only and are not used as comparison evidence.

