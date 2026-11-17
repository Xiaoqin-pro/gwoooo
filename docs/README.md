# Adaptive Leader GWO Prototype

MATLAB implementation for the GWO/APL experiments. Source files are in `../code/`, CEC reference data are in `../data/`, and all outputs are under `../results/`.

The initial legacy implementation has four variants:

- `gwo`: canonical three-leader GWO.
- `tournament`: keep the best current wolf as alpha; select the remaining leaders from better wolves with two distinct tournament sizes (default `[2 4]`).
- `adaptive`: evaluate proposals using 3, 4, and 5 sorted leaders, stopping at the first improvement.
- `combined`: build one ordered guide list using tournaments, then evaluate its 3/4/5-leader prefixes.

Those initial variants are retained as the legacy comparison. The APLPSO migration is implemented separately in `gwo_optimize_apl.m` with `apl_v2`, `apl_weighted`, `tournament_apl_v2`, and `tournament_apl_weighted`. The weighted combination is an explicit GWO transfer design; it is not an APLPSO formula.

Every initialization and proposal evaluation is charged to `MaxFEs`. When the adaptive variants find no improving proposal, they accept the best candidate evaluated in that attempt, matching the declared APL-inspired rule. The returned `BestPosition` and `BestFitness` are global best-so-far; that best is not reinserted into the population.

## Quick interface smoke run

From the project root, add `code/` to the MATLAB path and run `run_demo`. The sphere objective is only an interface check and must not be reported as benchmark evidence.

## CEC2022 development screening

The official organizer MEX and input data are bundled in `../data/CEC2022_reference/`; provenance and archive SHA-256 are in `../data/SOURCE.md`. `run_cec2022_pilot_6worker` runs a small F1/D=10 pilot, clearly separated from the actual benchmark campaign.

From the project root in MATLAB, run `addpath('code')` and then call `run_demo` or an experiment entry point. `run_cec2022_development(outputDir, seeds, workerCount, functionIds, dims, variants)` runs requested variants in a local MATLAB pool and checkpoints after every function/dimension block. `run_cec2022_apl_v2_development` runs six variants with seeds 41–50. The CEC2022 caps are 200,000 FEs at D=10 and 1,000,000 FEs at D=20.

Run `analyze_cec2022_development` for the legacy screen, or `analyze_cec2022_apl_v2` for the six-version APL screen, per-function residuals, average ranks, diagnostics, and unadjusted Wilcoxon rank-sum comparisons. These runs used fixed MaxFES termination; they do not implement the official 1e-8 early-termination score.

`gwo_optimize` expects row-vector bounds and an objective callback that accepts one 1-by-D row vector. The repository includes the unmodified CEC2022 reference MEX/source and input data; the optimization methods are maintained separately under `code/`.

## FAD-1 fallback ablation

The FAD runner supports an isolated FAD-1 configuration that disables only the individual GWO fallback after an APL gate failure. It keeps the generation-level FE-progress fallback and all other FAD mechanisms.

From the repository root in MATLAB:

```matlab
addpath('code');
run_fad_cec2022_dev([],41:50,6,1:12,[10 20],'FAD1');
analyze_fad1_cec2022();
```

The run is checkpointed in `results/fad1_no_individual_fallback_6worker_dev/`; completed RunKeys are skipped on resume. B0–B5 data are reused. This screen completed 240/240 new runs with exact FE budgets and no fallback calls. Across the seven-variant comparison its average function rank is 1.667; it remains a development result on the reused seeds 41–50, not an independent confirmation. See `../results/fad1_no_individual_fallback_6worker_dev/FAD1_REPORT.md` for the analysis and limits.

## FCLC-GWO Stage-1 mechanism screen

This is an independent branch from FAD. It compares standard GWO, fixed alpha-dominant weights, global leader credit (GCLC), and follower-specific counterfactual credit (FCLC), with a shared FE cap and seeds 41–50.

```matlab
addpath('code');
run_fclc_stage1_dev([],41:50,6);
analyze_fclc_stage1();
```

The runner reuses matching CEC2022 GWO rows for F1/F6 at D=10, and saves new runs, traces, and per-follower credit/weight diagnostics in `results/fclc_stage1_6worker_dev/`. The smoke run is separately stored in `results/fclc_stage1_smoke/` and is not benchmark evidence. The first screen ranked fixed weights first; see `../results/fclc_stage1_6worker_dev/FCLC_STAGE1_REPORT.md` before deciding whether this mechanism should be expanded.

## APL conditional recovery screen

The current APL branch tests two parent-acceptance rules around APL weighted patterns and conditional masked DLM-2 recovery. A8 accepts the best evaluated APL candidate after all tried patterns fail to improve the current wolf; A9 retains the original wolf in that case. The runner only adds missing A8/A9 runs and reuses matching A0/A2/A7 rows.

```matlab
addpath('code');
run_apl_handoff_cec2022();
analyze_apl_handoff();
```

This screen is complete: 480 new rows, seeds 41–50, CEC2022 F1–F12 at D=10/20, N=30, six workers, and exact FE budgets. Raw per-seed rows, merged comparisons, diversity traces, diagnostics, and the report are in `results/apl_handoff_6worker_dev/`. A9 has the best overall rank, while its rank is weaker at D=20 than A7; see `APL_HANDOFF_REPORT.md` for the per-dimension and unadjusted rank-sum results.

## Current status

The legacy, APL, staged A0–A7, FAD B5/B6, FCLC Stage-1, and APL conditional recovery screens are complete. The active line is APL conditional recovery; FAD and FCLC remain preserved as separate historical branches. Results are indexed in `../results/README.md`. See `implement-stage/apl_handoff/ASSUMPTIONS.md` and `implement-stage/apl_handoff/BUILD_NOTE.md` for the current method choices and build record.
