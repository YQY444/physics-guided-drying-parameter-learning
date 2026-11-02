# Physics-Guided Drying Parameter Learning

A MATLAB scientific-computing project coupling Newton–Lewis drying dynamics with a small neural parameter map. The operating conditions determine a positive rate constant; the analytical model produces water-loss trajectories and target times.

## Model

`L(t) = A (1 - exp(-k t))`, with run-specific reference capacity `A`. Compare a four-coefficient log-linear map with a 3–4–1 MLP (21 trainable parameters). Both are fitted through the same normalized curve loss.

## Validation and reported results

The study covers 27 operating conditions, 79 experimental runs and 14,665 observations. Outer leave-one-condition-out validation keeps all repeats together; inner grouped validation selects the weight penalty. Three seeds are reported separately.

| Metric (median across runs) | Log-linear | MLP, seed 17 |
| --- | ---: | ---: |
| Curve RMSE (g) | 279.63 | 254.48 |
| Absolute t90 error (min) | 59.51 | 51.84 |
| Absolute relative k error (%) | 21.34 | 16.59 |

These correspond to 9.0% lower median curve RMSE and 12.9% lower median target-time error. `t90` is the first crossing of 90% of the reference removable water, not the manually recorded stop time. The reference mass is used as the equilibrium-mass approximation. The minute observations come from processed offline curves; independent weighing calibration is needed for online deployment.

## Run

MATLAB R2023b (base MATLAB; analytical gradients and Adam are implemented in the source).

```matlab
run('examples/demo_newton_lewis.m') % no dataset required
run_study                        % uses included data/drying_curves.csv
```

The prepared experimental CSV is included at [`data/drying_curves.csv`](data/drying_curves.csv). Clone or download this repository and run `run_study` to reproduce the experimental workflow. The code creates result and figure folders automatically. See `data/README.md` for provenance, column definitions and exclusions.

## Structure

- `data/drying_curves.csv`: 14,665 processed experimental observations.
- `src/run_project.m`: parameter estimation, nested grouped validation, metrics and figures.
- `examples/`: synthetic analytical illustration.
- `figures/workflow.drawio` and `.svg`: editable research workflow (Times New Roman).
- `results/summary.json`: saved aggregate study results.

Original experiments were provided by a collaborating research group. This project concerns computational modeling, data preparation and validation. Manuscript status: in preparation. No preprint DOI has been assigned to this repository. No license is granted over collaborator datasets.
