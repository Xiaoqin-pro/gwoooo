# A0–A7 分阶段组合筛选

**日期：** 2026-11-14  
**阶段：** 10 种子开发筛选；复用已完成结果，不引入新种子。  
**并行：** MATLAB R2025b，本地 6-worker Processes pool。

## 实验构成

- A0–A5：直接复用 `cec2022_stage1_missing_6worker/A0_A5_merged.csv` 中已有 1,440 行。
- A6：APL-weighted + DLM-2 + 排名 BDL（自适应 K）。
- A7：APL-weighted + DLM-2 + 固定 50% BDL（控制）。
- A6/A7 只补跑缺失的组合：CEC2022 F1–F12、D=10/20、seeds 41–50，共 480 次。
- 新跑 480/480 为 `OK`，FE 全部匹配上限；总合并表 1,920 行。

这轮没有运行其余组合。按阶段一的结果，PTL-P 未进入阶段二；只选 DLM-2 与 BDL 做组合验证。A6/A7 不重新跑 A0–A5。

## A0–A7 平均排名

排名基于每个函数/维度的 10 次运行平均残差误差，再对 24 个设置取平均；越低越好。

| 算法 | 平均排名 | 最佳均值设置数 / 24 |
|---|---:|---:|
| A2 DLM-2 | 3.375 | 4 |
| A6 DLM-2 + 排名 BDL | 3.333 | 4 |
| A7 DLM-2 + 固定 50% BDL | 3.333 | 8 |
| A1 DLM-1 | 3.875 | 2 |
| A5 PTL-P | 5.458 | 2 |
| A4 固定 50% BDL | 5.208 | 2 |
| A3 排名 BDL | 5.417 | 2 |
| A0 APL-weighted | 6.000 | 0 |

## 配对显著性

沿用同种子配对 Wilcoxon signed-rank，并在每个对比的 24 个函数/维度设置内做 Holm 校正：

- A6 vs A0：0/24 设置 Holm 校正后 p<0.05。
- A7 vs A0：3/24 设置 Holm 校正后 p<0.05。
- A6 vs A2：0/24；A7 vs A2：0/24。
- A7 vs A4（检验 DLM-2 加入固定 BDL 后的变化）：2/24。
- A6 vs A7：0/24。

A7 在最优均值设置数上最多，且与 A6 平均排名并列；但 A6/A7 之间没有显著差异。当前数据支持把 A7 作为较有前景的组合候选继续观察，不能据此声称固定维度组合显著优于排名 BDL。总体比较使用复用的开发种子，属于筛选证据。

## 文件

- `A6_A7_new_runs.csv` / `.mat`：只含新增 A6/A7 的 480 行原始运行。
- `A0_A7_merged.csv`：复用 A0–A5 加新增 A6/A7 的完整表。
- `A6_A7_diversity_trace_1pct.csv`：A6/A7 每 1% FE 的维度标准差多样性轨迹。
- `A0_A7_per_function.csv`、`A0_A7_algorithm_summary.csv`、`A0_A7_signedrank_holm.csv`、`A0_A7_friedman.csv`：统计输出。

注意：旧 A0–A5 运行的多样性汇总使用 pairwise-distance 指标，A6/A7 使用维度标准差指标；两种多样性数值不混合比较。旧数据没有 1% FE 完整曲线，A6/A7 曲线单独留存。
