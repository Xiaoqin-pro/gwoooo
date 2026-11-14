# FAD-GWO Development Screen

**Stage:** 10-seed development run, seeds 41–50 reused from the existing B0–B4 studies.  
**MATLAB:** R2025b, local 6-worker Processes pool.  
**Benchmark:** CEC2022 F1–F12, D=10/20, N=30, bounds [-100,100].

## Reuse and run integrity

- B0–B4 were read from existing result tables and were not re-executed.
- Only B5 (FAD-GWO) was run: 240 jobs, seeds 41–50.
- All 240 B5 jobs completed with `Status=OK`; 120 D=10 runs used 200,000 FEs and 120 D=20 runs used 1,000,000 FEs.
- `B0_B5_merged.csv` has 1,440 rows: 1,200 reused baseline rows plus 240 new B5 rows.
- Every fixed-budget run went to MaxFES. These are development results, not the official 1e-8 early-termination score or an independent confirmation.

## B0–B5 ranking

Ranks are based on mean residual error within each function/dimension, then averaged over the 24 settings; lower is better.

| Version | Average rank | Best mean-error cases / 24 |
|---|---:|---:|
| B4 APL + DLM-2 + BDL-50 | 2.208 | 10 |
| B2 APL + DLM-2 | 2.417 | 5 |
| B3 APL + BDL-50 | 3.208 | 3 |
| B5 FAD-GWO | 3.458 | 6 |
| B1 APL-weighted | 3.708 | 0 |
| B0 GWO | 6.000 | 0 |

The table is a development ranking, not a declaration that the lowest-ranked algorithm is final. B5 improves substantially over vanilla GWO, but ranks below the simpler B2 and B4 versions.

## Paired tests

Pairwise Wilcoxon signed-rank tests compare B5 with each reused baseline over the 10 same-seed runs in each of 24 function/dimension settings. Holm correction is applied across those 24 settings separately for each contrast.

- B5 vs B0 GWO: Holm-adjusted p<0.05 in 20/24 settings; 231/240 seed pairs favored B5.
- B5 vs B1 APL-weighted: p<0.05 in 4/24; 110/240 favored B5 and 130/240 favored B1.
- B5 vs B2 APL+DLM-2: p<0.05 in 7/24; 89/240 favored B5 and 151/240 favored B2.
- B5 vs B3 APL+BDL-50: p<0.05 in 6/24; 126/240 favored B5 and 114/240 favored B3.
- B5 vs B4 APL+DLM-2+BDL-50: p<0.05 in 7/24; 87/240 favored B5 and 153/240 favored B4.

## Mechanism diagnostics

- Mean APL five-exemplar gate pass rate: 16.7%.
- Mean individual state: 0.331 (D=10) and 0.318 (D=20).
- Mean selected dimension count K: 7.40 (D=10) and 14.49 (D=20).
- Mean DLM target count: 3.89 wolves per generation.
- DLM difference-step first success rate: 26.6% at D=10 and 21.9% at D=20.
- DLM second-step success rate conditional on an attempted second mutation: 24.6% at D=10 and 22.0% at D=20.
- The APL-gate fallback used 45.5% of the FE budget at D=10 and 45.7% at D=20. This is a large share of the algorithm's work and is a likely source of behavior that needs an ablation before attributing performance to the feedback layers.

Dimension diagnostics use normalized per-coordinate standard deviation, as specified for FAD. Earlier APL result files logged a different pairwise-distance diversity metric; those values are not mixed here. The B0–B4 rows lack FAD state and dimension-memory traces, so those fields are intentionally blank for reused baselines.

## Interpretation

FAD-GWO is not the lead candidate yet: it loses in average rank and in more seed pairs to both APL+DLM-2 baselines. The strong fallback frequency should be isolated first. If continuing the FAD branch, the most informative next ablation is FAD-F (disable the APL-gate fallback) plus targeted state/dimension-layer ablations, using the same seeds and reusing B0–B5. Do not proceed directly to 30-seed confirmation until the fallback and layered feedback contribution are clarified.

## Output files

- `B5_FAD_new_runs.csv`: only new B5 run rows.
- `B0_B5_merged.csv`: reused B0–B4 plus new B5, with `Source` identifying provenance.
- `FAD_diversity_trace_1pct.csv`: B5 diversity sampled at 1% FE increments.
- `FAD_dimension_diagnostics.csv`: B5 dimension selection and feedback memory by run and dimension.
- `FAD_algorithm_summary.csv`, `FAD_per_function.csv`, `FAD_signedrank_holm.csv`, `FAD_friedman_by_function.csv`: analysis outputs.
