# FCLC-GWO Stage-1 mechanism screen

**Scope:** Sphere, Rastrigin, Rosenbrock, Ackley (D=30), CEC2022 F1/F6 (D=10); seeds 41–50; N=30; MATLAB local Processes, six workers.

**Completion:** 220 new runs, 220 OK, 0 failed; 20 reused GWO rows; 240 merged rows; all RunKeys unique and all FEs matched MaxFEs. No new seed IDs were introduced.

FCLC made a mean of 9.08% extra probe evaluations relative to MaxFEs; its mean final across-follower weight spread was 0.0078. Probe candidates updated credit only and did not replace population members.

## Average ranks

Lower is better. Best-mean counts include ties.

| Algorithm | Average problem rank | Best-mean/tied-best problems |
|---|---:|---:|
| WGWO_STATIC | 1.750 | 5/6 |
| GWO | 2.333 | 2/6 |
| FCLC | 2.583 | 1/6 |
| GCLC | 3.333 | 2/6 |

## FCLC pairwise results

Unadjusted Wilcoxon rank-sum p-values are shown per problem, without Holm correction, following the project preference. The seed IDs are matched, but this test does not use pairing. Rastrigin returned zero residual error for every run and therefore has a non-informative tie (p=1).

| Problem | Comparator | FCLC wins/losses | Mean relative error improvement (%) | p |
|---|---|---:|---:|---:|
| SPHERE | GWO | 0/10 | -0.000 | 0.0001827 |
| SPHERE | WGWO_STATIC | 0/10 | -0.000 | 0.0001827 |
| SPHERE | GCLC | 6/4 | 0.000 | 0.3847 |
| RASTRIGIN | GWO | 0/0 | 0.000 | 1 |
| RASTRIGIN | WGWO_STATIC | 0/0 | 0.000 | 1 |
| RASTRIGIN | GCLC | 0/0 | 0.000 | 1 |
| ROSENBROCK | GWO | 4/6 | 0.047 | 0.4274 |
| ROSENBROCK | WGWO_STATIC | 3/7 | -0.380 | 0.3075 |
| ROSENBROCK | GCLC | 5/5 | 0.215 | 0.9097 |
| ACKLEY | GWO | 0/1 | -0.036 | 0.3681 |
| ACKLEY | WGWO_STATIC | 2/1 | 0.036 | 0.5828 |
| ACKLEY | GCLC | 0/1 | -0.036 | 0.3681 |
| CEC2022_F1_D10 | GWO | 8/2 | 24.598 | 0.04515 |
| CEC2022_F1_D10 | WGWO_STATIC | 5/5 | -33.795 | 0.273 |
| CEC2022_F1_D10 | GCLC | 9/1 | 38.692 | 0.01726 |
| CEC2022_F6_D10 | GWO | 4/6 | -725.436 | 0.162 |
| CEC2022_F6_D10 | WGWO_STATIC | 1/9 | -2898.448 | 0.005795 |
| CEC2022_F6_D10 | GCLC | 6/4 | 21.041 | 1 |

## Mechanism diagnostics

The FCLC credit/weight diagnostics are in `FCLC_stage1_diagnostics_summary.csv` and `FCLC_weight_diagnostics.csv`; 1%-FE traces are in `FCLC_stage1_trace_1pct.csv` and `FCLC_stage1_mean_trace.csv`. Stage-1 trace checkpoints use the first completed generation at or above each FE threshold; for no-probe GWO, best-evaluated equals best-propagated. The per-run `MeanWeight*` and `WeightSpread` fields are terminal stored-credit diagnostics computed after final leader re-ranking, before a potential next-generation follower reset; the trace contains the weights actually applied during the run. The small smoke can sample GWO initialization for thresholds below N=30 and is not comparison evidence. Historical reused GWO rows did not contain convergence traces, so no synthetic GWO curve is shown for CEC F1/F6.

## Interpretation

The fixed alpha-dominant weighting ranked first overall (1.750); standard GWO ranked 2.333, FCLC 2.583, and GCLC 3.333. FCLC beat GCLC on average rank but did not outperform the fixed-weight or standard-GWO baselines overall. Its follower-specific weights remained near equal on average. The current screen therefore does not support advancing to FCLC+DLM or FCLC+APL yet; first inspect why the counterfactual credit produced limited weight separation. These are exploratory 10-seed results, not confirmation or a novelty verdict.
