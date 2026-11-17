# Build Specification — APL Conditional Recovery

**Target:** Extend the existing APL-weighted GWO branch with a conditional, partial-dimension DLM-2 recovery path. Keep the old APL variants and FAD/FCLC branches unchanged.

**Core sequence:** Run the existing weighted APL 3/4/5 pattern search. If it improves the current wolf, accept the first improving pattern and skip DLM. If it does not improve (including failure of the all-five-better gate), a preselected worst-20%-nonelite target receives a DLM-2 Laplace-difference recovery step on 50% of dimensions. The second DLM attempt is made only after the first succeeds. Compare A8 (the original archive fallback) with A9 (strict retention when APL fails).

**Inputs:** Existing APL stage-1 implementation, bundled CEC2022 MEX/data, and matching A0/A2/A7 results from `results/cec2022_stage2_combo_6worker/`.

**Outputs:** New `apl_handoff_archive` and `apl_handoff_strict` variants in `code/gwo_optimize_apl_stage1.m`, plus an isolated runner/analysis and results under `results/apl_handoff_6worker_dev/`.

**Protocol:** CEC2022 F1–F12, D=10/20; N=30; seeds 41–50; MaxFEs 200,000 / 1,000,000; MATLAB local Processes, 6 workers. Run only new A8/A9 configurations and reuse A0/A2/A7.

**Success command:** `matlab -batch "cd('D:/111/Desktop/1/gwo_dev'); addpath('code'); run_apl_handoff_cec2022(); analyze_apl_handoff();"`

**Base commit:** `b09f1fed499b7ca6c982b800b3891f8b8c61eccc`.

**Scope cuts:** No FCLC, FAD, RL controller, tournament leader selection, new seeds, or 30-seed confirmation in this screen.
