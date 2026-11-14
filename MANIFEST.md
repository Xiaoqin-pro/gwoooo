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
| 2026-11-14 09:07 | /research-lit | `docs/FCLC_FORMULA_COMPARISON_20261114_081617.md` | implementation | Initial formula comparison based on local RL-LGWO and DLGWO papers. |
| 2026-11-14 09:07 | /research-refine | `docs/FCLC_FORMULA_COMPARISON_20261114_090742.md` | implementation | Formula comparison updated with the Stage-1 screen outcome and next decision. |
| 2026-11-14 09:07 | /research-refine | `docs/FCLC_FORMULA_COMPARISON.md` | implementation | Latest FCLC formula comparison and Stage-1 status. |
| 2026-11-14 09:07 | /research-implement-feature | `implement-stage/SPEC.md` | implementation | FCLC-GWO Stage-1 implementation target and scope cuts. |
| 2026-11-14 09:07 | /research-implement-feature | `implement-stage/ASSUMPTIONS.md` | implementation | Pre-code ledger for method, benchmark, FE, seed, and output choices. |
| 2026-11-14 09:07 | /research-implement-feature | `implement-stage/BUILD_NOTE.md` | implementation | Four-rung implementation and execution record. |
| 2026-11-14 09:07 | /research-implement-feature | `code/gwo_optimize_fclc.m` | implementation | Independent FCLC/GCLC/static-weight GWO prototype. |
| 2026-11-14 09:07 | /research-implement-feature | `code/run_fclc_stage1_dev.m` | implementation | Six-worker runner with seed reuse and per-run checkpoints. |
| 2026-11-14 09:07 | /research-implement-feature | `code/run_fclc_stage1_smoke.m` | implementation | Small isolated Sphere smoke entry point. |
| 2026-11-14 09:07 | /research-implement-feature | `code/verify_fclc_modes.m` | implementation | FE and probe accounting check for the three prototype modes. |
| 2026-11-14 09:07 | /analyze-results | `code/analyze_fclc_stage1.m` | implementation | Per-problem ranks, unadjusted rank-sum tests, and diagnostic/trace summaries. |
| 2026-11-14 09:07 | /research-implement-feature | `results/fclc_stage1_smoke/FCLC_stage1_new_runs.csv` | implementation | Four-mode Sphere smoke outputs; interface check only. |
| 2026-11-14 09:07 | /research-implement-feature | `results/fclc_stage1_smoke/FCLC_stage1_merged.csv` | implementation | Smoke table including run provenance. |
| 2026-11-14 09:07 | /research-implement-feature | `results/fclc_stage1_smoke/FCLC_stage1_trace_1pct.csv` | implementation | Smoke best-so-far and weight traces. |
| 2026-11-14 09:07 | /research-implement-feature | `results/fclc_stage1_smoke/FCLC_weight_diagnostics.csv` | implementation | Smoke follower and role weights. |
| 2026-11-14 09:07 | /research-implement-feature | `results/fclc_stage1_smoke/FCLC_stage1_checkpoint.mat` | implementation | Smoke checkpoint. |
| 2026-11-14 09:07 | /research-implement-feature | `results/fclc_stage1_6worker_dev/FCLC_stage1_new_runs.csv` | implementation | 220 new stage-1 rows; 20 matching CEC GWO rows reused. |
| 2026-11-14 09:07 | /research-implement-feature | `results/fclc_stage1_6worker_dev/FCLC_stage1_merged.csv` | implementation | 240-row seed-matched GWO/static/GCLC/FCLC comparison. |
| 2026-11-14 09:07 | /research-implement-feature | `results/fclc_stage1_6worker_dev/FCLC_stage1_trace_1pct.csv` | implementation | 1%-FE search, weight, and probe traces. |
| 2026-11-14 09:07 | /research-implement-feature | `results/fclc_stage1_6worker_dev/FCLC_weight_diagnostics.csv` | implementation | Follower-role credit and weight state. |
| 2026-11-14 09:07 | /research-implement-feature | `results/fclc_stage1_6worker_dev/FCLC_stage1_checkpoint.mat` | implementation | Stage-1 checkpoint with reused and new rows. |
| 2026-11-14 09:07 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_stage1_per_problem.csv` | implementation | Per-problem mean errors and ranks. |
| 2026-11-14 09:07 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_stage1_algorithm_summary.csv` | implementation | Four-method average ranks and best/tied-best counts. |
| 2026-11-14 09:07 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_stage1_ranksum.csv` | implementation | Per-problem unadjusted Wilcoxon rank-sum results. |
| 2026-11-14 09:07 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_stage1_diagnostics_summary.csv` | implementation | Probe rate, role contribution, runtime, weight diagnostics. |
| 2026-11-14 09:07 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_stage1_mean_trace.csv` | implementation | Mean/std search and weight traces. |
| 2026-11-14 09:07 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT.md` | implementation | Stage-1 outcome, data validation, and interpretation limits. |
| 2026-11-14 09:07 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT_20261114_090742.md` | implementation | Timestamped Stage-1 report copy. |
| 2026-11-14 09:07 | /experiment-bridge | `README_20261114_090742.md` | implementation | Timestamped repository overview with FCLC branch status. |
| 2026-11-14 09:07 | /experiment-bridge | `README.md` | implementation | Latest repository overview with FCLC screen outcome. |
| 2026-11-14 09:07 | /experiment-bridge | `results/README_20261114_090742.md` | implementation | Timestamped experiment index with FCLC results. |
| 2026-11-14 09:07 | /experiment-bridge | `results/README.md` | implementation | Latest experiment index with FCLC results. |
| 2026-11-14 09:07 | /experiment-bridge | `docs/README_20261114_090742.md` | implementation | Timestamped usage notes for FCLC Stage-1. |
| 2026-11-14 09:07 | /experiment-bridge | `docs/README.md` | implementation | Latest usage notes for FCLC Stage-1. |
| 2026-11-14 09:07 | /experiment-bridge | `docs/PROJECT_SUMMARY_20261114_090742.md` | implementation | Timestamped project status with separate FAD/FCLC branches. |
| 2026-11-14 09:07 | /experiment-bridge | `docs/PROJECT_SUMMARY.md` | implementation | Latest project status with FCLC Stage-1 findings. |
| 2026-11-14 09:31 | /research-implement-feature | `implement-stage/SILENT_ASSUMPTION_SWEEP.json` | implementation | Raw first-round same-family assumption sweep and resolutions; a resweep is pending. |
| 2026-11-14 09:31 | /research-implement-feature | `implement-stage/ASSUMPTIONS.md` | implementation | Added sweep findings and corrected IQR, ranking, tracing, diagnostics, reuse, and failure semantics. |
| 2026-11-14 09:31 | /research-implement-feature | `implement-stage/BUILD_NOTE.md` | implementation | Records the first sweep verdict and corrections. |
| 2026-11-14 09:31 | /research-implement-feature | `code/run_fclc_stage1_dev.m` | implementation | Corrected GWO trace resampling to use the same FE-threshold convention. |
| 2026-11-14 09:31 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_stage1_trace_1pct.csv` | implementation | Corrected no-probe GWO propagated-best checkpoints from stored evaluated-best trace. |
| 2026-11-14 09:31 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_stage1_mean_trace.csv` | implementation | Regenerated after trace-semantic correction. |
| 2026-11-14 09:31 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT_20261114_093115.md` | implementation | Timestamped report clarifying trace and terminal-weight meanings. |
| 2026-11-14 09:31 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT.md` | implementation | Latest Stage-1 report. |
| 2026-11-14 09:31 | /research-refine | `docs/FCLC_FORMULA_COMPARISON_20261114_093115.md` | implementation | Timestamped formula comparison and Stage-1 outcome. |
| 2026-11-14 09:31 | /research-refine | `docs/FCLC_FORMULA_COMPARISON.md` | implementation | Latest formula comparison and branch status. |
| 2026-11-14 09:31 | /experiment-bridge | `docs/PROJECT_SUMMARY_20261114_093115.md` | implementation | Timestamped project summary with FCLC diagnosis and FAD/FCLC separation. |
| 2026-11-14 09:31 | /experiment-bridge | `docs/PROJECT_SUMMARY.md` | implementation | Latest project summary with FCLC Stage-1 findings. |
| 2026-11-14 09:31 | /research-implement-feature | `implement-stage/SILENT_ASSUMPTION_SWEEP.json` | implementation | Raw round-1 assumption sweep, corrections, and resweep status. |
| 2026-11-14 09:31 | /research-implement-feature | `implement-stage/ASSUMPTIONS.md` | implementation | Ledger records sweep corrections and declared statistics/trace/cache semantics. |
| 2026-11-14 09:31 | /research-implement-feature | `implement-stage/BUILD_NOTE.md` | implementation | Build record notes sweep findings and pending resweep. |
| 2026-11-14 09:31 | /research-implement-feature | `code/run_fclc_stage1_dev.m` | implementation | Consistent first-generation-crossing GWO trace sampling and FE-compatible cache skip. |
| 2026-11-14 09:31 | /analyze-results | `code/analyze_fclc_stage1.m` | implementation | Report clarifies terminal next-generation weight diagnostics. |
| 2026-11-14 09:31 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_stage1_trace_1pct.csv` | implementation | GWO propagated-best trace repaired from stored evaluated-best values. |
| 2026-11-14 09:31 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_stage1_checkpoint.mat` | implementation | Checkpoint trace corrected; fitness and RunKeys unchanged. |
| 2026-11-14 09:31 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_stage1_mean_trace.csv` | implementation | Regenerated after GWO trace correction. |
| 2026-11-14 09:31 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT.md` | implementation | Latest trace/weight semantics and result interpretation. |
| 2026-11-14 09:31 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT_20261114_093115.md` | implementation | Timestamped Stage-1 report. |
| 2026-11-14 09:41 | /research-implement-feature | `implement-stage/ASSUMPTIONS.md` | implementation | Clarified smoke trace and pre-reset terminal weight diagnostic semantics after sweep round 2. |
| 2026-11-14 09:41 | /research-implement-feature | `implement-stage/BUILD_NOTE.md` | implementation | Added sweep round-2 follow-up and current resweep status. |
| 2026-11-14 09:41 | /research-implement-feature | `code/run_fclc_stage1_dev.m` | implementation | Keeps first-generation-crossing trace semantics across the smoke path. |
| 2026-11-14 09:41 | /analyze-results | `code/analyze_fclc_stage1.m` | implementation | Clarifies terminal stored-credit weights and applied trace semantics. |
| 2026-11-14 09:41 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT_20261114_093115.md` | implementation | Timestamped report with applied-vs-terminal weight definitions. |
| 2026-11-14 09:41 | /analyze-results | `results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT.md` | implementation | Latest report with applied-vs-terminal weight definitions. |
| 2026-11-14 09:41 | /research-refine | `docs/FCLC_FORMULA_COMPARISON_20261114_094127.md` | implementation | Timestamped formula comparison with stage-1 and audit corrections. |
| 2026-11-14 09:41 | /research-refine | `docs/FCLC_FORMULA_COMPARISON.md` | implementation | Latest formula comparison and audit status. |
| 2026-11-14 09:41 | /experiment-bridge | `docs/PROJECT_SUMMARY_20261114_094127.md` | implementation | Timestamped status distinguishing the FAD and FCLC branches. |
| 2026-11-14 09:41 | /experiment-bridge | `docs/PROJECT_SUMMARY.md` | implementation | Latest status with corrected FCLC weight diagnostic meaning. |
| 2026-11-14 09:46 | /research-implement-feature | `implement-stage/SILENT_ASSUMPTION_SWEEP.json` | implementation | Round-2 same-family/provisional sweep returned no remaining undeclared or stale ledger choices. |
| 2026-11-14 09:46 | /research-implement-feature | `implement-stage/BUILD_NOTE.md` | implementation | Records completed round-2 resweep and its provisional status. |
