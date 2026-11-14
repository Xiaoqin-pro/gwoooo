# FAD-1：移除个体级 GWO 回退的故障定位结果

**实验日期：** 2026-11-14  
**实验目的：** 检查 FAD-0 在 APL 门控失败后执行的个体级 GWO 回退是否影响性能。  
**结论范围：** CEC2022 开发筛选；沿用 seeds 41–50，不是独立确认实验。

## 实验定义

FAD-1 只关闭 APL 门控失败后的个体级 GWO 回退。APL、维度反馈、动态 DLM、恢复项和 APL 候选档案规则均保持不变。FAD 仍保留“整代没有发生任何评价时，额外评价一次以推进 FE”的全代兜底规则。

`code/gwo_optimize_fad.m` 新增 `DisableIndividualFallback` 选项，默认值为 `false`，因此默认调用仍运行原 FAD-0 规则。FAD-1 runner 显式将其设为 `true`。FAD-0 原始代码记录和结果文件未被替换。

| 设置 | 值 |
|---|---:|
| 基准 | CEC2022，F1–F12 |
| 维度 | 10、20 |
| 种群 | 30 |
| seeds | 41–50（复用） |
| MaxFEs | D=10：200,000；D=20：1,000,000 |
| 并行 | MATLAB R2025b，local Processes，6 workers |
| 新增运行 | FAD-1：240；B0–B5 全部复用 |

## 完成与完整性检查

- FAD-1 共 240/240 条运行成功，所有 RunKey 唯一。
- D=10 与 D=20 各 120 条；FEs 与对应 MaxFEs 完全匹配。
- `IndividualFallbackCount` 总和为 0，`GenerationFallbackCount` 总和也为 0。
- 原有随机五狼 APL 门控通过率约为 16.7%；其余算法机制保持启用。
- 新增的每 1% FE best-so-far 和多样性轨迹已保存。

## 主要比较

平均排名基于 24 个“函数 × 维度”设置，越低越好；最佳均值次数统计每个设置中残差误差均值最低的算法。

| 算法 | 平均排名 | 最佳均值设置 |
|---|---:|---:|
| B6 FAD-1（无个体级回退） | **1.667** | **14/24** |
| B4 APL + DLM-2 + BDL-50 | 2.958 | 4/24 |
| B2 APL + DLM-2 | 3.250 | 3/24 |
| B3 APL + BDL-50 | 4.125 | 0/24 |
| B5 原 FAD-0 | 4.333 | 3/24 |
| B1 APL weighted | 4.667 | 0/24 |
| B0 GWO | 7.000 | 0/24 |

每种对比均在同一函数、维度下按 seed 配对，使用 Wilcoxon signed-rank 检验；Holm 校正在每个对比的 24 个设置内分别进行。

| FAD-1 对比 | 配对胜 / 负（240 次） | Holm 显著设置 | 显著方向 |
|---|---:|---:|---|
| B5 原 FAD-0 | 199 / 41 | **14/24** | 14 项均支持 FAD-1 |
| B4 APL + DLM-2 + BDL-50 | 178 / 62 | **5/24** | 5 项均支持 FAD-1 |
| B2 APL + DLM-2 | 169 / 71 | 6/24 | 6 项均支持 FAD-1 |
| B1 APL weighted | 188 / 52 | 9/24 | 9 项均支持 FAD-1 |
| B3 APL + BDL-50 | 189 / 51 | 8/24 | 8 项均支持 FAD-1 |
| B0 GWO | 235 / 5 | 23/24 | 23 项均支持 FAD-1 |

按 24 个函数—维度设置分别计算“FAD-1 相对对照算法的均值误差改善率”，其中位数为：相对 FAD-0 **30.56%**（21/24 项均值更好），相对 B4 **11.04%**（18/24 项均值更好），相对 B2 **6.03%**（20/24 项均值更好）。

分维度平均排名：D=10 时 FAD-1 为 1.58、FAD-0 为 4.58、B4 为 2.75；D=20 时 FAD-1 为 1.75、FAD-0 为 4.08、B4 为 3.17。两个维度上都观察到类似排序。

## 故障定位诊断

FAD-0 原始文件中的 `FallbackCount` 占其总 FE 的 45.69%。该历史字段没有区分个体级回退与整代兜底，因此 45.69% 是旧版回退调用比例的汇总估计，无法从旧表中精确拆分两类回退。FAD-1 已新增独立计数，并且本次 240 条运行中两类回退都未触发。

FAD-1 的平均 APL 门控通过率为 17%。DLM-1 首次扰动成功率在 D=10/20 分别为 8%/6%；第二次扰动成功率分别为 15%/11%。每次运行的耗时、门控率、DLM 成功率和两类 fallback 计数记录在 `B6_FAD1_new_runs.csv`。

## 轨迹文件与历史限制

- `FAD1_search_trace_1pct.csv`：每个 FAD-1 run 的 100 点 best-so-far 目标值轨迹与多样性轨迹。
- `FAD1_convergence_by_run.csv`、`FAD1_mean_convergence.csv`：FAD-1 残差误差收敛曲线原始长表与种子均值/标准差。
- `FAD0_FAD1_mean_diversity.csv`：复用旧 FAD-0 多样性轨迹，并与 FAD-1 按函数、维度和 FE 百分比汇总。
- FAD-0 首轮没有保存 best-so-far 收敛轨迹。因此不能从已有 FAD-0 数据恢复其收敛曲线；本轮没有重跑 FAD-0。其最终误差和多样性轨迹仍可直接比较。

## 解释边界

这轮结果强烈支持“移除个体级 GWO 回退”作为当前 FAD 版本的修正：FAD-1 在本开发筛选中超过 FAD-0，并且也超过原先表现较好的 B4。它仍是 seeds 41–50 上的筛选结果，不能当作独立确认；也不能据此判断维度反馈、恢复项或 APL 档案接受规则各自是否有效，因为本轮只改变了个体级回退。

## 结果文件

- `B6_FAD1_new_runs.csv`：240 条新运行及每次运行的诊断指标。
- `B0_B6_merged.csv`：B0–B5 复用数据与 B6 新数据的合并表，共 1,680 行。
- `FAD1_dimension_diagnostics.csv`：逐运行、逐维度的反馈诊断。
- `FAD1_signedrank_holm.csv`、`FAD1_per_function.csv`、`FAD1_algorithm_summary.csv`：配对统计与排名表。
- `FAD1_friedman_by_function.csv`：各函数/维度的 Friedman 诊断。
- `FAD1_diagnostics_summary.csv`：运行时间、门控、DLM 与 fallback 汇总。
- `FAD_checkpoint.mat`：可恢复的运行与轨迹 checkpoint（FAD-1 独立目录中的文件）。

复现入口：`run_fad_cec2022_dev([],41:50,6,1:12,[10 20],'FAD1')`；分析入口：`analyze_fad1_cec2022()`。已完成的 RunKey 会跳过，不会重复运行。
