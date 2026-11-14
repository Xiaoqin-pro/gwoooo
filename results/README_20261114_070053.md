# Experiment results index

All experiment outputs are kept under this `results/` directory. Each subfolder contains the raw run table, checkpoints and analysis for one experiment stage.

| Folder | Content | Status |
|---|---|---|
| `cec2022_6worker_dev/` | Legacy GWO/Tournament/old adaptive/combined screen, seeds 1–10 | Complete; historical comparison |
| `cec2022_apl_v2_6worker_dev/` | Six-version APL migration screen, seeds 41–50 | Complete |
| `cec2022_stage1_missing_6worker/` | A0–A5; A0 reused, A1–A5 newly run, seeds 41–50 | Complete |
| `cec2022_stage2_combo_6worker/` | A0–A7; A0–A5 reused, A6/A7 newly run, seeds 41–50 | Complete |
| `cec2022_tournament_confirmation_6worker/` | Partial fresh-seed check: F1/D=10 only, seeds 11–40 | Interrupted by user; not full confirmation |
| `fad_gwo_6worker_dev/` | B5 FAD-GWO development screen; B0–B4 reused, only B5 run, seeds 41–50 | Complete; see `FAD_REPORT.md` |
| `fad1_no_individual_fallback_6worker_dev/` | B6 FAD-1 fallback ablation; B0–B5 reused, only B6 run, seeds 41–50 | Complete; 240/240 OK; see `FAD1_REPORT.md` |
| `pilot_6worker/` | Initial CEC interface pilot | Complete; smoke only |
| `apl_v2_pilot_6worker/` | APL six-variant F1/D=10 pilot | Complete; smoke only |

The staged A0–A7 table is `cec2022_stage2_combo_6worker/A0_A7_merged.csv`; the FAD comparison tables are `fad_gwo_6worker_dev/B0_B5_merged.csv` and `fad1_no_individual_fallback_6worker_dev/B0_B6_merged.csv`. Each identifies reused and newly executed rows in the `Source` column.
