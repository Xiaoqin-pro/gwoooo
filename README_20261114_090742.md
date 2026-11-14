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

The project now has two separate lines. The established FAD branch retains its original code and results; FAD-1 removes only the individual GWO fallback. A new FCLC-GWO branch tests sparse, follower-specific counterfactual leader credit without importing FAD/APL/DLM/BDL. Its first-stage 10-seed screen is in `results/fclc_stage1_6worker_dev/`; fixed alpha-dominant weights ranked first, so the FCLC mechanism has not yet earned a larger benchmark campaign. All new experiments reused seed IDs 41–50 and are development screens, not independent confirmation. Result files and run manifests are under `results/`.

## Benchmark source

CEC2022 source/data provenance and the downloaded archive hash are recorded in `data/SOURCE.md`. The organizer-provided MEX and input data are retained unchanged.
