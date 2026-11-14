# APL-GWO v2 Development Screen

**Date:** 2026-11-14  
**Stage:** 10-seed development screen; not confirmatory.  
**MATLAB:** R2025b, six local Processes workers.  
**Seeds:** 41–50, held apart from the earlier 1–10 screen and the interrupted 11–40 F1/D=10 subset.

## Method versions

- `gwo`: legacy canonical GWO, called through an instrumented copy that adds a diversity trace without changing its update equations.
- `tournament`: legacy tournament-guided GWO.
- `apl_v2`: random five exemplars excluding the current wolf; enter APL only when all five are strictly better; use equal-weight GWO proposals for prefix patterns k=3,4,5; stop on first improvement; if none improves, accept the best evaluated archive candidate.
- `apl_weighted`: same APL selection and archive, but combine the k GWO proposals using normalized rank weights based on the APLPSO coefficient schedule.
- `tournament_apl_v2` / `tournament_apl_weighted`: form five distinct exemplars by alternating tournament sizes 2 and 4, then apply the same all-five-dominate gate and respective pattern combiner.

The verified source coefficient is `c1 = 1`, and for `j = 2..5`, `cj = 1/(j-1) - (FE/MaxFE)/(j+1)`. The user-suggested GWO transfer normalizes these weights before combining GWO leader proposals; this normalized combination is our transfer design, not the original APLPSO formula. Candidate evaluations are all charged to the same FE budget.

## Run integrity

- CEC2022 F1–F12, D=10 and 20, bounds [-100,100].
- MaxFES 200,000 (D=10), 1,000,000 (D=20); population 30.
- Six versions × 12 functions × 2 dimensions × 10 seeds = **1,440 runs**.
- **1,440/1,440 `OK`; 0 failures; 0 FE mismatches.** Total: 864,000,000 objective calls; summed per-run runtime 22,078.1 seconds.
- Every trial ran to MaxFES. This is a fixed-budget development screen, not the CEC official 1e-8 early-termination score.

## Main screening results

Ranks use mean residual error per function/dimension pair, then average across 24 pairs. Lower is better.

| Variant | Average rank | Best mean error cases / 24 |
|---|---:|---:|
| APL weighted | 1.750 | 12 |
| APL v2 equal-weight | 2.208 | 7 |
| Tournament + APL weighted | 3.000 | 4 |
| Tournament + APL v2 | 3.333 | 1 |
| Tournament only | 4.833 | 0 |
| GWO | 5.875 | 0 |

Unadjusted Wilcoxon rank-sum tests were used as requested; no Holm correction was applied. On 24 function/dimension settings:

- APL v2 vs GWO: `p < 0.05` in 23/24; 236/240 run-level comparisons favored APL v2.
- APL v2 vs Tournament: `p < 0.05` in 22/24; 230/240 favored APL v2.
- APL weighted vs GWO: `p < 0.05` in 22/24; 231/240 favored APL weighted.
- APL weighted vs APL v2: `p < 0.05` in only 1/24; 126/240 favored weighted, 114/240 favored equal-weight.
- Tournament + APL v2 vs APL v2: `p < 0.05` in 5/24; 86/240 favored the hybrid, 154/240 favored APL v2.
- Tournament + APL weighted vs APL weighted: `p < 0.05` in 7/24; 89/240 favored the hybrid, 151/240 favored weighted APL alone.

These p-values are exploratory and unadjusted across many function-level comparisons. They should not be presented as confirmatory evidence.

## Diagnostics

- Random-five APL gate pass rate averaged about 16.7%; tournament-five gate pass rate averaged about 41.5%.
- The weighted APL had more pattern-3 improvements and fewer pattern-4/5 improvements than equal-weight APL, consistent with the intended stronger early-ranked guidance.
- Archive acceptance remained common after all three patterns failed to improve the current wolf (about 44–45% of gate-passing cases).
- Population diversity decreased sharply in all variants; the recorded per-run diversity traces can be used to diagnose convergence and collapse by function.

## Interpretation and next step

This run answers the main question: **the fuller APL migration is promising and should not be discarded.** Tournament selection used to choose five guides increases gate pass rate but does not improve the APL result; both hybrid versions rank below their corresponding APL-only versions. Keep tournament as a standalone comparator, not a component of the current lead method.

The equal-weight and weighted APL variants are close under direct unadjusted rank-sum comparison. Use APL v2 as the simpler main candidate for a fresh 30-seed confirmation; retain APL weighted as a competing ablation. Only after that confirmation should we add another distinct mechanism such as stagnation-triggered Laplace perturbation, with a four-way ablation (GWO, APL, Laplace, APL+Laplace) and a new seed split.

## Output files

- `cec2022_development.csv` / `.mat`: 1,440 run-level rows and full metadata.
- `cec2022_apl_v2_per_function.csv`: per-function residual errors and ranks.
- `cec2022_apl_v2_algorithm_ranks.csv`: aggregate ranks.
- `cec2022_apl_v2_rank_sum_unadjusted.csv`: all configured unadjusted comparisons.
- `cec2022_apl_v2_friedman_unadjusted.csv`: unadjusted omnibus diagnostic p-values.
- `cec2022_apl_v2_diagnostics.csv`: gate, mode, archive, and diversity summaries.
