# APL Conditional Recovery Screen

**Protocol:** CEC2022 F1–F12, D=10/20, N=30, seeds 41–50, six MATLAB workers; MaxFEs=200,000 at D=10 and 1,000,000 at D=20.

**New runs:** 480 A8/A9 rows, 480 OK, 0 non-OK; 720 matching A0/A2/A7 rows reused. Merged rows: 1200. All rows used fixed MaxFEs.

A8 runs weighted APL patterns first, then applies masked DLM-2 only to selected worst-20% non-elites whose APL step did not improve. A9 uses the same handoff but retains the old position instead of accepting the non-improving APL archive.

## Average ranks

Lower is better; ranks average across 24 function/dimension settings. Best-mean counts include ties.

| Algorithm | Average rank | Best/tied-best settings |
|---|---:|---:|
| A9_APL_HandoffStrict | 2.125 | 15/24 |
| A7_DLM2_BDL50 | 2.625 | 4/24 |
| A2_DLM2 | 2.958 | 2/24 |
| A8_APL_HandoffArchive | 3.042 | 2/24 |
| A0_APLweighted | 4.250 | 1/24 |

## Average ranks by dimension

Ranks are first computed from the 12 function-wise 10-seed mean errors within each dimension, then averaged.

| Dimension | A0 APL-weighted | A2 DLM-2 | A7 DLM-2+BDL50 | A8 archive | A9 strict |
|---:|---:|---:|---:|---:|---:|
| 10 | 4.500 | 3.333 | 2.833 | 2.750 | 1.583 |
| 20 | 4.000 | 2.583 | 2.417 | 3.333 | 2.667 |

## Pairwise tests

Unadjusted two-sided Wilcoxon rank-sum tests are reported per setting without Holm correction, following the project screen preference. Seed IDs match, but the test is unpaired. Direction among significant settings is based on the difference in mean residual error.

| Method | Comparator | Significant p<.05 | Favor method / comparator | Seed wins / losses |
|---|---|---:|---:|---:|
| A8_APL_HandoffArchive | A0_APLweighted | 6/24 | 5 / 1 | 147 / 93 |
| A8_APL_HandoffArchive | A2_DLM2 | 1/24 | 1 / 0 | 123 / 117 |
| A8_APL_HandoffArchive | A7_DLM2_BDL50 | 5/24 | 1 / 4 | 109 / 131 |
| A8_APL_HandoffArchive | A9_APL_HandoffStrict | 17/24 | 5 / 12 | 80 / 160 |
| A9_APL_HandoffStrict | A0_APLweighted | 20/24 | 15 / 5 | 168 / 72 |
| A9_APL_HandoffStrict | A2_DLM2 | 18/24 | 12 / 6 | 158 / 82 |
| A9_APL_HandoffStrict | A7_DLM2_BDL50 | 18/24 | 13 / 5 | 161 / 79 |
| A9_APL_HandoffStrict | A8_APL_HandoffArchive | 17/24 | 12 / 5 | 160 / 80 |

## Diagnostics

| Variant | Gate pass | Archive selections | Handoff opportunities | Handoff triggers | Strict retains | Mean DLM successes |
|---|---:|---:|---:|---:|---:|---:|
| A8_APL_HandoffArchive | 0.167 | 96725.4 | 225765.4 | 144243.4 | 0.0 | 46965.5 |
| A9_APL_HandoffStrict | 0.150 | 0.0 | 197840.9 | 197430.7 | 132630.9 | 3658.0 |

## Interpretation

A9 ranks first overall and at D=10, while A7 has a better average rank than A9 at D=20. The total ranking therefore hides a dimension-dependent result. A9 keeps the original wolf after all APL patterns fail; A8 instead selects the best evaluated APL candidate, which can still be worse than the original wolf, before any eligible DLM recovery. This screen is consistent with preserving the incumbent before recovery, but does not establish why the difference occurs.

DLM success counts are not directly comparable between A8 and A9: A8 tests improvement relative to its archived candidate, while A9 tests relative to the retained incumbent. The screen reuses matching seed IDs and is not independent confirmation. Per-seed raw rows are in `A8_A9_new_runs.csv` and `A0_A2_A7_A8_A9_merged.csv`; per-function summaries, diversity traces, and diagnostics are stored beside this report. These development results do not establish broad novelty or paper readiness.
