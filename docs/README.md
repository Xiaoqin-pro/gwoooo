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

## Current status

The legacy 960-run screen, APL migration 1440-run screen, staged A0–A7 experiment, and FAD-GWO B5 screen completed on six MATLAB workers. Results are indexed in `../results/README.md`. See `implement-stage/ASSUMPTIONS.md` for design decisions and `implement-stage/BUILD_NOTE.md` for follow-up work.
