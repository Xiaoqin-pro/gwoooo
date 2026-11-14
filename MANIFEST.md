# Research Output Manifest

> Auto-maintained output list for experiment and analysis artifacts.

| Timestamp | Skill | File | Stage | Description |
|-----------|-------|------|-------|-------------|
| 2026-11-14 07:00 | /experiment-bridge | `code/gwo_optimize_fad.m` | implementation | Added optional individual-fallback disable switch, separated fallback counters, and best-so-far trace. |
| 2026-11-14 07:00 | /experiment-bridge | `code/run_fad_cec2022_dev.m` | implementation | Added FAD-1 mode, isolated output folder, reused-seed filtering, and trace export. |
| 2026-11-14 07:00 | /analyze-results | `code/analyze_fad1_cec2022.m` | implementation | Added paired comparison, Holm correction, convergence/diversity summaries, and diagnostics. |
| 2026-11-14 07:00 | /experiment-bridge | `results/fad1_no_individual_fallback_6worker_dev/B6_FAD1_new_runs.csv` | implementation | 240 new FAD-1 run rows on seeds 41–50. |
| 2026-11-14 07:00 | /experiment-bridge | `results/fad1_no_individual_fallback_6worker_dev/B0_B6_merged.csv` | implementation | Reused B0–B5 rows plus new B6 results. |
| 2026-11-14 07:00 | /experiment-bridge | `results/fad1_no_individual_fallback_6worker_dev/FAD1_dimension_diagnostics.csv` | implementation | Per-run, per-dimension feedback diagnostics. |
| 2026-11-14 07:00 | /experiment-bridge | `results/fad1_no_individual_fallback_6worker_dev/FAD1_search_trace_1pct.csv` | implementation | FAD-1 best-so-far and diversity traces at 1% FE increments. |
| 2026-11-14 07:00 | /experiment-bridge | `results/fad1_no_individual_fallback_6worker_dev/FAD_checkpoint.mat` | implementation | Checkpoint containing merged results and traces. |
| 2026-11-14 07:00 | /analyze-results | `results/fad1_no_individual_fallback_6worker_dev/FAD1_per_function.csv` | implementation | Per-function, per-dimension residual-error summaries and ranks. |
| 2026-11-14 07:00 | /analyze-results | `results/fad1_no_individual_fallback_6worker_dev/FAD1_algorithm_summary.csv` | implementation | Seven-variant average ranks and best-mean counts. |
| 2026-11-14 07:00 | /analyze-results | `results/fad1_no_individual_fallback_6worker_dev/FAD1_signedrank_holm.csv` | implementation | Seed-paired signed-rank comparisons with per-comparator Holm correction. |
| 2026-11-14 07:00 | /analyze-results | `results/fad1_no_individual_fallback_6worker_dev/FAD1_friedman_by_function.csv` | implementation | Friedman diagnostics for each function and dimension. |
| 2026-11-14 07:00 | /analyze-results | `results/fad1_no_individual_fallback_6worker_dev/FAD1_diagnostics_summary.csv` | implementation | Runtime, gate, DLM-success, and fallback summary. |
| 2026-11-14 07:00 | /analyze-results | `results/fad1_no_individual_fallback_6worker_dev/FAD1_convergence_by_run.csv` | implementation | FAD-1 per-run residual-error convergence traces. |
| 2026-11-14 07:00 | /analyze-results | `results/fad1_no_individual_fallback_6worker_dev/FAD1_mean_convergence.csv` | implementation | FAD-1 convergence mean and standard deviation by FE percentage. |
| 2026-11-14 07:00 | /analyze-results | `results/fad1_no_individual_fallback_6worker_dev/FAD0_FAD1_mean_diversity.csv` | implementation | Reused FAD-0 and new FAD-1 diversity curves. |
| 2026-11-14 07:00 | /analyze-results | `results/fad1_no_individual_fallback_6worker_dev/FAD1_REPORT_20261114_065743.md` | implementation | Timestamped experiment report, statistics, diagnostics, and scope limits. |
| 2026-11-14 07:00 | /analyze-results | `results/fad1_no_individual_fallback_6worker_dev/FAD1_REPORT.md` | implementation | Latest report copy. |
| 2026-11-14 07:00 | /experiment-bridge | `README_20261114_070053.md` | implementation | Timestamped repository overview with FAD-1 status. |
| 2026-11-14 07:00 | /experiment-bridge | `README.md` | implementation | Latest repository overview. |
| 2026-11-14 07:00 | /experiment-bridge | `results/README_20261114_070053.md` | implementation | Timestamped experiment-results index. |
| 2026-11-14 07:00 | /experiment-bridge | `results/README.md` | implementation | Latest experiment-results index. |
| 2026-11-14 07:00 | /experiment-bridge | `docs/README_20261114_070053.md` | implementation | Timestamped experiment usage notes. |
| 2026-11-14 07:00 | /experiment-bridge | `docs/README.md` | implementation | Latest experiment usage notes. |
| 2026-11-14 07:00 | /experiment-bridge | `docs/PROJECT_SUMMARY_20261114_070053.md` | implementation | Timestamped project summary with FAD-1 results and status. |
| 2026-11-14 07:00 | /experiment-bridge | `docs/PROJECT_SUMMARY.md` | implementation | Latest project summary with FAD-1 results and status. |
