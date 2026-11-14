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

APLPSO-inspired adaptive pattern learning has been transferred to GWO and screened against DLM, BDL, and PTL-P variants. The code keeps the original GWO/early APL versions for comparison. Development runs used seeds 41–50 and are not an independent confirmation campaign. Result files and exact run manifests are under `results/`.

## Benchmark source

CEC2022 source/data provenance and the downloaded archive hash are recorded in `data/SOURCE.md`. The organizer-provided MEX and input data are retained unchanged.
