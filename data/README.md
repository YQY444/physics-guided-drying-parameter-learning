# Experimental dataset

`drying_curves.csv` contains the processed experimental data used by `run_study.m`: **14,665 observations, 79 experimental runs and 27 operating conditions**. It is included in the repository and can be downloaded directly. 

The dataset is copied without numerical changes from the study's prepared master table (`01_干燥曲线主表.csv`). Its UTF-8 BOM Chinese headers are skipped by MATLAB; numeric column order matches `schema.csv`.

| Column | Meaning | Unit |
| --- | --- | --- |
| 1 | Experimental run ID | — |
| 2 | Operating condition ID | — |
| 3 | Inlet temperature T | °C |
| 4 | Dry-air mass flow G | kg/h |
| 5 | Inlet humidity ratio omega | g/kg |
| 6 | Elapsed time | min |
| 7 | Processed wet-fabric mass | g |
| 8 | Cumulative water loss | g |
| 9 | Initial mass | g |
| 10 | Reference mass | g |
| 11 | Reference removable-water capacity A | g |
| 12 | Row in the source table | — |

One row is one time point. Keep repeats from the same condition together during validation. `loss_g = initial_mass_g - fabric_mass_g`; `Aref_g = initial_mass_g - reference_mass_g`. Run 18 has no valid processed fabric mass; run 61 has a duration mismatch, so both are excluded from this prepared dataset. The processed series includes smoothing and endpoint calibration. Original Excel workbooks and unrelated project materials are not included.

Original experiments were provided by a collaborating research group. This repository distributes the prepared study dataset; no separate open-data license is asserted here.
