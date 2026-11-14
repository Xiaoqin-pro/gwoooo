# Specification — Adaptive Leader GWO prototype

## Target
Build a MATLAB prototype that compares canonical GWO, tournament-guided GWO, adaptive leader-count GWO, and their combination under an explicit function-evaluation budget.

## Inputs
- Objective callback accepting one row-vector candidate and returning one scalar.
- Lower/upper bounds, dimension, population size, maximum FEs, variant, and random seed.
- Optional stagnation-aware Laplace perturbation for a later rung.

## Outputs
- MATLAB source under the repository root (`code/`).
- Per-run best-so-far trace and metadata including exact objective-call count.
- A development driver configured for CEC2022 F1–F12 at D=10/20 when the official CEC callback is supplied.

## Success command
`run_demo` from MATLAB; runtime acceptance remains unclaimed because the command was not run in this build turn.

## Base commit
none (the target folder is not a Git repository).

## Scope cuts
No copied CEC benchmark implementation, no paper-ready comparison campaign, and no application model in this first build. The benchmark adapter will call a user-supplied official CEC2022 function.
