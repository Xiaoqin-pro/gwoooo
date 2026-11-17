# Build Note — APL Conditional Recovery

| Rung | Feature | Acceptance check (ONE command) | Tier | Status |
|------|---------|-------------------------------|------|--------|
| F0 | Add A8/A9 conditional recovery modes without changing existing APL variants | `matlab -batch "cd('D:/111/Desktop/1/gwo_dev'); addpath('code'); run_apl_handoff_smoke();"` | MUST | ✅ |
| F1 | Check A8 archive vs A9 strict acceptance, DLM triggers and FE accounting | `matlab -batch "cd('D:/111/Desktop/1/gwo_dev'); addpath('code'); verify_apl_handoff_modes();"` | MUST | ✅ |
| F2 | Run only A8/A9 on CEC2022; reuse A0/A2/A7 and seeds 41–50 | `matlab -batch "cd('D:/111/Desktop/1/gwo_dev'); addpath('code'); run_apl_handoff_cec2022();"` | MUST | ✅ |
| F3 | Rank/compare, inspect archive and DLM diagnostics | `matlab -batch "cd('D:/111/Desktop/1/gwo_dev'); addpath('code'); analyze_apl_handoff();"` | MUST | ✅ |

## Run record

- F0/F1 smoke and mode checks passed before the benchmark run.
- F2 produced 480/480 successful A8/A9 runs (240 per variant) across F1–F12, D=10/20, seeds 41–50, using six MATLAB workers. The 720 matching A0/A2/A7 rows were reused. All 1,200 merged rows have unique RunKeys and exact FE/MaxFEs matches.
- F3 generated the per-function table, average ranks, unadjusted per-setting rank-sum comparisons, diagnostics, mean diversity traces, and `results/apl_handoff_6worker_dev/APL_HANDOFF_REPORT.md`.
- A9 (`APL_HandoffStrict`) ranks first overall (2.125), and first at D=10 (1.583); at D=20 A7 ranks first (2.417) and A9 is third (2.667). This is a development screen on reused seeds, not an independent confirmation.
- The archive and strict variants use different reference fitness for DLM success counts after APL failure, so those counts should not be compared as a standalone measure of recovery quality.
- Analysis-script regeneration initially stopped on a local-scope variable error; the script was corrected and the analysis then completed successfully. Raw experiment results were unaffected.

## Deferred

- New seed confirmation, full application validation, and any APL + FCLC combination.

## Blockers

- None for the completed development screen. Independent confirmation and application validation remain deferred.
