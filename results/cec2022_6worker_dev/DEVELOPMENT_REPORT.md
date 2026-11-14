# CEC2022 Development Screening — Six MATLAB Workers

**Run date:** 2026-11-13  
**Purpose:** development screening; not a confirmatory paper result.  
**MATLAB:** R2025b, local Processes pool, 6 workers.  
**Benchmark source:** CEC2022 reference bundle recorded in `../../data/SOURCE.md`.

## Protocol

- Functions F1–F12, dimensions 10 and 20, bounds [-100,100].
- 10 seeds per function/dimension and four variants: `gwo`, `tournament`, `adaptive`, `combined`.
- Population size 30; tournament sizes [2,4].
- MaxFES: 200,000 for D=10 and 1,000,000 for D=20.
- Every run used the full FE budget. No task failed and no run exceeded its budget.
- Total: 960 runs, 576,000,000 objective evaluations, 7,893.2 summed per-run seconds.
- The initial 48-run F1/D=10 pilot used 1,000 FEs per run and is stored separately under `../pilot_6worker/`.

## Screening signal

The ranking below is computed from mean residual error within each function/dimension pair, then averaged over 24 pairs. This avoids pooling raw CEC objective values with very different scales.

| Variant | Average rank (lower is better) | Best mean error on |
|---|---:|---:|
| Tournament | 1.500 | 14/24 pairs |
| Combined | 1.875 | 9/24 pairs |
| GWO | 3.292 | 1/24 pairs |
| Adaptive | 3.333 | 0/24 pairs |

Across the 24 paired function/dimension settings, paired Wilcoxon tests with Holm correction within each contrast found:

- Tournament vs GWO: 194/240 seed pairs favored tournament; 5/24 settings remained significant after Holm correction.
- Adaptive vs GWO: 137/240 seed pairs favored adaptive; 1/24 settings remained significant after Holm correction. Its average rank was essentially baseline-level and it was best on none of the 24 settings.
- Combined vs Tournament: 129/240 seed pairs favored the combination; 1/24 settings remained significant after Holm correction. The combination did not improve the average rank over tournament alone.

These are screening results from 10 seeds, so they select the next experiment rather than establish a final claim. The next run should confirm the tournament mechanism on fresh seeds; the current data do not support retaining APL as a claimed benefit. Do not add Laplace perturbation to this run after seeing these results.

After the user requested a pause before continuing, a separate fresh-seed confirmation job had already completed only F1/D=10 (seeds 11–40, GWO and tournament: 60 runs). It was stopped before any other function/dimension; these rows are stored in `../cec2022_tournament_confirmation_6worker/` and are not a full-suite confirmation.

## Important interpretation boundary

This batch ran every trial to MaxFES. It does not implement early termination when error first falls below 1e-8, so it is not the official CEC competition terminal-score protocol. Compare final residual errors and FE-matched traces only; use the prescribed termination accounting for any formal CEC-style score.

## Output files

- `cec2022_development.csv` and `.mat`: all run-level records.
- `cec2022_per_function_summary.csv`: residual mean/median/std and per-function ranks.
- `cec2022_algorithm_summary.csv`: aggregate screening ranks.
- `cec2022_pairwise_wilcoxon_holm.csv`: paired win/loss/tie counts and adjusted p-values.
- `cec2022_friedman_by_function.csv`: per-setting Friedman p-values (unadjusted; diagnostic only).
