# Build Note — FCLC-GWO Stage 1

| Rung | Feature | Acceptance check (ONE command) | Tier | Status |
|------|---------|-------------------------------|------|--------|
| F0 | End-to-end FCLC runner on a small Sphere smoke case; real algorithm, isolated smoke artifacts | `matlab -batch "cd('D:/111/Desktop/1/gwo_dev'); addpath('code'); run_fclc_stage1_smoke();"` | MUST | ✅ |
| F1 | Follower/global/fixed credit modes and diagnostics | `matlab -batch "cd('D:/111/Desktop/1/gwo_dev'); addpath('code'); verify_fclc_modes();"` | MUST | ✅ |
| F2 | Six-worker synthetic + representative CEC stage-1 campaign; reuse matching GWO rows | `matlab -batch "cd('D:/111/Desktop/1/gwo_dev'); addpath('code'); run_fclc_stage1_dev([],41:50,6);"` | MUST | ✅ |
| F3 | Per-function summaries, ranks, unadjusted rank-sum tests, and probe/weight diagnostics | `matlab -batch "cd('D:/111/Desktop/1/gwo_dev'); addpath('code'); analyze_fclc_stage1();"` | MUST | ✅ |

## Run record

- F0 smoke: four modes on Sphere, seed 41, N=30, MaxFEs=300; 4/4 rows `OK`, exact FE cap. An initial smoke attempt exposed a missing empty-diagnostic helper for the GWO baseline; added the helper and reran the same RunKeys successfully.
- F1 mode check: static/GCLC/FCLC all used exactly 300 FEs; static performed zero probes and both credit modes performed probes.
- F2 stage-1 screen: 220 new runs on six problems and seeds 41–50, six MATLAB workers; 220/220 `OK`, 20 CEC GWO rows reused, no FE mismatches.
- F3 analysis: six-problem average ranks and unadjusted rank-sum comparisons; report and CSV artifacts written under `results/fclc_stage1_6worker_dev/`.
- Assumption sweep: corrected A-002 Rosenbrock bounds; declared GCLC per-generation role aggregation, linear-IQR interpolation, next-generation terminal-weight semantics, analysis/error conventions, trace threshold semantics, cache reuse checks, and run failure handling. The GWO propagated trace bug was fixed in code and saved CSV/checkpoints; no objective values or final ranks changed.
- Sweep round 1 verdict was `gaps` (8 semantic findings, 2 interface findings, 1 stale ledger row). Corrections are documented in `ASSUMPTIONS.md`.
- The round-2 resweep found no remaining undeclared choices or stale rows after clarifying that smoke trace thresholds can precede initialization and terminal weights are pre-reset stored-credit diagnostics. Review status is same-family/provisional and does not certify method correctness.

## Deferred

- Full CEC2022 F1–F12 at D=10/20.
- APL, DLM, BDL, FAD, application validation, and 30-seed confirmation.

## Blockers

- Stage-1 performance does not support advancing to FCLC+DLM/APL yet; inspect the limited follower-weight separation and weak comparison to the fixed-weight baseline first.
