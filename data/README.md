# Experimental data

The collaborator-provided measurements are not redistributed here. With permission, copy the prepared CSV as `data/drying_curves.csv`. The numeric column order must match `schema.csv`; the original preparation uses UTF-8 BOM Chinese headers, which are skipped by MATLAB.

One row is one time point. IDs group repeated observations by experimental run and operating condition. Mass is in grams and time in minutes. `loss_g = initial_mass_g - fabric_mass_g`; `Aref_g = initial_mass_g - reference_mass_g`. The reported study uses 79 runs at 27 conditions (14,665 points). Run 18 has no valid processed fabric mass; run 61 has a duration mismatch. The processed source series includes smoothing and endpoint calibration.
