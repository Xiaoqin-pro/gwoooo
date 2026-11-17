# GWO Optimization Study

MATLAB research workspace for the APL-GWO development and CEC2022 experiments.

## Layout

- `code/` — MATLAB algorithms, experiment runners, and analysis scripts.
- `data/CEC2022_reference/` — the CEC2022 MEX function and required input data.
- `data/CEC2022_source_code/` — source package used to build/inspect the CEC functions.
- `docs/` — project summary, usage notes, and the implementation ledger.
- `results/` — one directory per pilot, screening, or staged experiment; see `results/README.md`.

The separate `article/` literature folder is kept outside this repository and is not uploaded here.

## Quick start

From this directory in MATLAB:

```matlab
addpath('code');
run_demo;
```

To run a saved CEC2022 screening entry point, the runner accepts a six-worker local pool and writes checkpoints under `results/`. See `docs/README.md` for the available runners and the result interpretation boundaries.

## Current research stage

The active research direction is the APL-GWO branch. Its latest CEC2022 screen compares conditional DLM-2 recovery with two acceptance rules: `A8_APL_HandoffArchive` accepts the best evaluated APL candidate when none improves the current wolf, while `A9_APL_HandoffStrict` retains the current wolf before recovery. The 10-seed screen is complete in `results/apl_handoff_6worker_dev/`; A9 ranks first overall, with a dimension-dependent result that is documented in the report. FAD and FCLC remain separate historical branches with their code and results preserved. These are development screens on reused seed IDs 41–50, not independent confirmation. Result files and run manifests are under `results/`.

## Benchmark source

CEC2022 source/data provenance and the downloaded archive hash are recorded in `data/SOURCE.md`. The organizer-provided MEX and input data are retained unchanged.
