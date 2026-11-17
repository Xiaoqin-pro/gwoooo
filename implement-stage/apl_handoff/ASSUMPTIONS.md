# Assumption Ledger — APL Conditional Recovery
<!-- ASK mode: never -->

| ID | Under-determined by the request | Chosen | Class | Source |
|----|--------------------------------|--------|-------|--------|
| APLH-001 | Which APL variant is the backbone? | Use `apl_weighted`: random five exemplars, all-five-better gate, weighted 3/4/5 patterns, shared random coefficients. | semantic | existing APL screen + default |
| APLH-002 | When does the recovery operator run? | Only when this wolf's APL attempt fails to improve, including failure of the all-five gate; successful APL updates skip DLM. | semantic | user direction |
| APLH-003 | Which wolves are eligible for DLM recovery? | Select the current worst 20% of nonelite wolves by fitness rank each generation; keep the top three protected. | semantic | existing DLM-2 screen |
| APLH-004 | How is DLM-2 coupled to dimension-limited updating? | Apply a random mask of `ceil(0.5*D)` dimensions to both APL patterns and DLM difference steps; sample one mask per targeted wolf/update and reuse it for all its APL patterns and both DLM attempts. | semantic | user direction + default |
| APLH-005 | How does recovery handle non-improvement? | DLM candidate replaces the current trial only when strictly better; the second DLM attempt occurs only after the first improves the trial. | semantic | existing DLM-2 rule |
| APLH-006 | What distinguishes A8/A9? | A8 keeps the current best evaluated APL archive candidate after failed patterns. A9 keeps the old position instead. Both can then try the same conditional DLM recovery if targeted. | semantic | user direction |
| APLH-007 | What parameters and FE protocol apply? | Laplace(0.6,0.3), DLM target fraction .20, elite count 3, N=30; all initialization, APL, and DLM objective calls count toward the same MaxFEs. | semantic | existing project protocol |
| APLH-008 | Which seeds and baselines should be used? | Seeds 41–50; reuse A0 APL-weighted, A2 DLM-2, and A7 DLM-2+BDL50 rows. Run only missing A8/A9. | semantic | prior user preference |
| APLH-009 | Which statistics are reported? | Per-setting mean-error ranks and unadjusted Wilcoxon rank-sum tests without Holm correction, preserving the project preference. | semantic | prior user instruction |

## Notes

- **APLH-002** makes DLM a recovery route rather than an unconditional second operator.
- **APLH-004** applies BDL50 to the APL pattern proposals and the DLM recovery proposal; this is a conditional transfer design, not a reproduction of a source algorithm.
- **APLH-006** isolates whether non-improving archive replacement helps when both variants share the same recovery trigger.
