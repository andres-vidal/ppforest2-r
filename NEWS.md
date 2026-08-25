# ppforest2 0.1.3

## New features

- `summary()` on a classification tree or forest now reports a per-class error rate alongside each confusion matrix, and prints the overall error rate above the matrix rather than below it. A class with no observations in the data is shown as `-` rather than `nan%` — this happens when the model predicts a class that never appears as an actual label, for example when predicting on a subset of the data.

## Bug fixes

- The resolved thread count is clamped to at least 1 — `hardware_concurrency()` may report 0, and a non-positive OpenMP thread count is undefined behavior.

# ppforest2 0.1.2

## CRAN

- Fixed a `-Wdeprecated-declarations` warning reported by CRAN's macOS/M1mac additional check (Apple clang 21, macOS 26 SDK). The newer libc++ deprecates `std::char_traits<unsigned char>`, which the vendored nlohmann/json instantiates through its binary output/stream adapters (`std::basic_string<std::uint8_t>` / `std::basic_ostream<std::uint8_t>`). ppforest2 does not use the nlohmann/json binary formats, so the vendored `json.hpp` is now bracketed with a `_Pragma` guard that suppresses the deprecation. `_Pragma` (unlike `#pragma`) is not flagged by `R CMD check`'s pragma check. The guard is applied by `make r-vendor-deps` (`scripts/vendor-guard-json.sh`).

# ppforest2 0.1.1

## Packaging and build

- The package now compiles the C++ core directly through `Makevars` instead of CMake, with no network access or downloaded dependencies at install time. Eigen is provided by RcppEigen; nlohmann/json and pcg headers are vendored under `inst/include`. This makes the package installable on CRAN's offline build machines.
- Self-registering strategies are compiled directly into the shared object, removing the previous whole-archive linking workaround.
- Compiler flags mirror the standalone C++ build — `EIGEN_NO_AUTOMATIC_RESIZING` on all platforms and `EIGEN_DONT_VECTORIZE` on Windows.
- Replaced C++20 designated initializers and fixed member-initialization order in the vendored core so it compiles warning-free under a strict C++17 GCC (`-Wall -Wextra -pedantic`).
- A compile-time `EIGEN_VERSION_AT_LEAST(3, 4, 0)` guard fails the build with a clear message if an incompatible Eigen is supplied via RcppEigen.
- `make r-vendor-deps` re-vendors the committed json/pcg headers after a version bump.

## Documentation

- `DESCRIPTION` uses `Authors@R` and cites the projection-pursuit tree and forest references with DOIs.
- Examples for the parsnip and plot methods use `\donttest` with `requireNamespace()` guards instead of `\dontrun`, so they run under `--run-donttest` when the suggested packages are available.

## CRAN

- Added `cran-comments.md`. The package passes `R CMD check --as-cran` with no errors or warnings; remaining notes (new submission, cosmetic pragmas in the vendored nlohmann/json headers) are documented for the reviewer.

# ppforest2 0.1.0

## New features

- Projection-pursuit oblique decision trees and random forests for classification, using LDA/PDA optimization.
- `pptr()` and `pprf()` with formula and matrix interfaces. Returned models carry an S3 class vector identifying both model type and mode (e.g. `c("pprf_classification", "pprf", "ppmodel")`).
- `predict()` returns group labels (`type = "class"`) or vote proportions (`type = "prob"`) for classification.
- Random uniform variable selection per split for forest diversity.
- Three variable importance measures: permuted (VI1), projections (VI2), and weighted projections (VI3). Permuted variable importance may be negative; this is meaningful signal ("within noise") rather than a sentinel, so callers should rely on the ranking rather than clipping at zero. Weighted projection importance is non-negative by construction.
- Out-of-bag error and confusion matrix for forests, with bootstrap sample indices persisted for recomputation.
- Lazy OOB accessors — `oob_error()`, `oob_predictions()`, `oob_samples()`, `bag_samples()`, `permuted_importance()`, `weighted_importance()` — compute from the training data stored on the model on first access and memoize in an environment cache, so training is fast and repeated access is free. `oob_error()` is `NA_real_` and `oob_predictions()` returns a factor with `NA` for rows with no OOB tree.
- `summary()` displays training and OOB confusion matrices.
- Degenerate split detection when projection pursuit cannot find a useful projection, surfaced as a warning.
- OpenMP multi-threaded forest training.
- `save_json()` and `load_json()` for model persistence. Optional metrics fields use a uniform `null`-or-value representation so downstream tooling can distinguish "computed but empty" from other shapes without special-casing.
- Cross-platform reproducibility — identical results for the same seed on Linux, macOS, and Windows, enforced by golden-file tests in CI.
- tidymodels/parsnip integration: `pp_tree()` and `pp_rand_forest()` model specifications.
- ggplot2 visualizations — tree diagrams, variable importance plots, projection histograms, and decision boundary plots.
- Bundled classification datasets: crab, crabs, fishcatch, glass, image, leukemia, lymphoma, NCI60, olive, parkinson, and wine. (Use `datasets::iris` from base R for iris examples.)

## Experimental features

Regression support is included but untested in production workloads. API surface and defaults may change in future releases.

- Regression auto-detected when `y` is numeric (not a factor). `predict()` returns a numeric vector (`type = "response"`).
- Regression strategy wrappers: `grouping_by_cutpoint()`, `leaf_mean_response()`, `stop_min_size()`, `stop_min_variance()`, `stop_any()`. Training quantile-slices the continuous response into groups and fits mean-response leaves.
- `summary()` displays MSE / MAE / R² for regression models, computed for training and out-of-bag predictions; forest OOB error is reported as MSE. `oob_predictions()` returns a numeric vector with `NA_real_` for rows with no OOB tree.
- `save_json()` / `load_json()` preserve regression mode; parsnip `pp_tree()` / `pp_rand_forest()` accept `mode = "regression"`.
- Bundled regression dataset `california_housing` (20,433 × 9, predict `median_house_value`). For smaller regression examples use `datasets::mtcars` from base R.
