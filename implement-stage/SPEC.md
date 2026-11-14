# Build Specification — FCLC-GWO Stage 1

**Target:** Add an independent FCLC-GWO research branch and run a small mechanism screen. FAD code and results remain a separate branch.

**Inputs:** Existing standard GWO implementation; the repository's CEC2022 MEX for F1 and F6; deterministic Sphere, Rastrigin, Rosenbrock, and Ackley objectives.

**Outputs:** `code/gwo_optimize_fclc.m`, a six-worker stage-1 runner and analysis entry point, and raw run/diagnostic/trace CSV files under `results/fclc_stage1_6worker_dev/`.

**Protocol:** N=30; D=30 for synthetic functions; D=10 for CEC2022 F1/F6; seeds 41–50; synthetic MaxFEs=30,000; CEC2022 D=10 MaxFEs=200,000. Compare GWO, fixed weights `[0.6 0.3 0.1]`, global-credit GCLC, and follower-credit FCLC. Reuse existing GWO rows for CEC F1/F6 D=10 where seeds and FE caps match.

**Success command:** `matlab -batch "cd('D:/111/Desktop/1/gwo_dev'); addpath('code'); run_fclc_stage1_dev([],41:50,6); analyze_fclc_stage1();"`

**Base commit:** `95d7b5f2a8a0e52dc91dff3fda49e704a06f46cc`.

**Scope cuts:** No FAD/APL/DLM/BDL, no reinforcement-learning reproduction, no full CEC2022 sweep, and no application experiment in Stage 1.
