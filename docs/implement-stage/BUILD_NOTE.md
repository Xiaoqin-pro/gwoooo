# Build Note — Adaptive Leader GWO prototype

| Rung | Feature | Acceptance check | Tier | Status |
|------|---------|------------------|------|--------|
| F0 | MATLAB entry point, objective callback, output schema | CEC2022 pilot through a six-worker pool | MUST | Passed: 48 tasks |
| F1 | Canonical GWO and evaluation-budget accounting | Check run manifest and exact FE counts | MUST | Passed: 960 runs, no FE mismatch |
| F2 | Tournament-guided β/δ selection | Compare paired seeds against F1 | MUST | Passed: results recorded |
| F3 | Adaptive 3/4/5-guide candidate evaluation | Check all candidate evaluations against the FE cap | MUST | Passed: results recorded |
| F4 | Combined variant and CEC2022 callback driver | Run functions 1–12 at D=10/20 | MUST | Passed: 960 runs, 6 workers |
| F5 | Stagnation-aware Laplace perturbation | Add only after F1–F4 results justify it | DEFERRED | Deferred |
| F6 | Faithful APLPSO-to-GWO transfer | Implement random-five all-superior gate, sequential archive modes, and diagnostics | MUST | Passed: code in `code/gwo_optimize_apl.m` |
| F7 | Six-version APL screen | CEC2022 D=10/20, 10 fresh seeds, 6 workers; inspect FE caps and diagnostic CSV | MUST | Passed: 1440 runs, no failures |
| F8 | A0–A5 single-mechanism screen | Reuse A0 seeds 41–50; run only DLM1/2, BDL-rank/50, PTL-P | MUST | Passed: 1200 new runs, 0 failures |
| F9 | DLM2 + BDL combinations | Reuse A0–A5; run only rank-BDL and fixed-50% combinations | MUST | Passed: 480 new runs, 0 failures |
| F10 | FAD-GWO first full version | Reuse B0–B4; run B5 on CEC2022 D=10/20, seeds 41–50; check FEs and diagnostics | MUST | Passed: 240 new runs, 0 failures |

## Run record
- 2026-11-13: Inspected the workspace; it contains the separate `article/` literature library and no pre-existing project source repository.
- 2026-11-13: MATLAB R2025b launched the local Processes pool with 6 workers.
- 2026-11-13: CEC2022 driver configured for 12 functions, D=10/20 and official MaxFES values (200,000 and 1,000,000); development uses 10 seeds.
- 2026-11-13: 48-task pilot passed; full 960-task screening completed with zero failed tasks and exact FE caps. See `../../results/cec2022_6worker_dev/DEVELOPMENT_REPORT.md`.
- 2026-11-13: A fresh-seed confirmation job was stopped at the user's request after its F1/D=10 block (60/1440 runs); those partial rows are retained but not interpreted as full confirmation.
- 2026-11-14: Verified APLPSO source details (random five peers, all-five-superior gate, exact c_j schedule); added APL v2, weighted transfer, and tournament-combined variants without changing the original optimizer file.
- 2026-11-14: Six-version APL migration campaign completed: 1440/1440 runs, seeds 41–50, six workers, exact MaxFES. Report: `../../results/cec2022_apl_v2_6worker_dev/APL_V2_REPORT.md`.
- 2026-11-14: APL v2 and weighted APL lead the six-version development screen; tournament+APL variants rank below their corresponding APL-only variants. Rank-sum results are unadjusted as requested.
- 2026-11-14: Stage 1 reused A0 and completed A1–A5 (1200 new runs, same seeds 41–50); report: `../../results/cec2022_stage1_missing_6worker/STAGE1_A0_A5_REPORT.md`.
- 2026-11-14: Stage 2 reused A0–A5 and completed A6/A7 (480 new runs, same seeds 41–50); report: `../../results/cec2022_stage2_combo_6worker/STAGE2_A0_A7_REPORT.md`.
- 2026-11-14: FAD-GWO B5 completed on seeds 41–50; 240 new runs, 0 failures, B0–B4 reused. Report: `../../results/fad_gwo_6worker_dev/FAD_REPORT.md`.

## Deferred
- No new seed confirmation was run because the current instruction is to reuse seeds 41–50 and execute only missing designs.
- Additional combination variants and sensitivity sweeps remain unrun; Stage 2 tested only the two preselected DLM2+BDL combinations.
- FAD ablations (individual state, dimension success memory, diversity feedback, K schedule, and fallback) remain unrun; FAD's current fallback accounts for a large share of FE.
- CEC2022 early-termination-at-1e-8 accounting required for any official competition-style score; development screening ran all trials to MaxFES.
- Laplace perturbation until the core combination is benchmarked.

## Blockers
- No current execution blocker. Results are development screening only and do not yet establish a paper claim.
