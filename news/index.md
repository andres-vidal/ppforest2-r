# Changelog

## ppforest2 0.1.3

### New features

- [`summary()`](https://rdrr.io/r/base/summary.html) on a classification
  tree or forest now reports a per-class error rate alongside each
  confusion matrix, and prints the overall error rate above the matrix
  rather than below it. A class with no observations in the data is
  shown as `-` rather than `nan%` — this happens when the model predicts
  a class that never appears as an actual label, for example when
  predicting on a subset of the data.
- Text sizes in the tree structure plot are configurable through options
  (`ppforest2.text_edge`, `ppforest2.text_tick`, `ppforest2.text_leaf`,
  `ppforest2.text_proj`), and `ppforest2.text_scale` multiplies all of
  them at once for rendering the plot large.

### Bug fixes

- Projection coefficients in the tree structure plot are formatted to
  three significant digits instead of two fixed decimals, matching the
  axis tick labels in the same plot. The projector is normalized so the
  values it projects always have the same spread whatever the units of
  the input data, which leaves its coefficients at a magnitude set by
  the data rather than by the split; the iris root projector
  `.00429 / -.0391 / .0259 / .0335` rendered as `.00 / .04 / .03 / .03`,
  merging the two petal terms and dropping sepal length to zero.
- [`pptr()`](https://andres-vidal.github.io/ppforest2-r/reference/pptr.md)
  and
  [`pprf()`](https://andres-vidal.github.io/ppforest2-r/reference/pprf.md)
  no longer abort with the internal error
  `Grouping::init: partition must be rooted at row 0` when the
  response’s class blocks are contiguous but ordered by decreasing
  factor level (for example a two-class factor whose first row is its
  second level, or the bundled `crab` dataset with default alphabetical
  levels). The classification path now sorts the response into ascending
  group-id order whenever it is not already, matching the regression
  path and the command-line tool.
- The resolved thread count is clamped to at least 1 —
  `hardware_concurrency()` may report 0, and a non-positive OpenMP
  thread count is undefined behavior.

## ppforest2 0.1.2

CRAN release: 2026-07-21

### CRAN

- Fixed a `-Wdeprecated-declarations` warning reported by CRAN’s
  macOS/M1mac additional check (Apple clang 21, macOS 26 SDK). The newer
  libc++ deprecates `std::char_traits<unsigned char>`, which the
  vendored nlohmann/json instantiates through its binary output/stream
  adapters (`std::basic_string<std::uint8_t>` /
  `std::basic_ostream<std::uint8_t>`). ppforest2 does not use the
  nlohmann/json binary formats, so the vendored `json.hpp` is now
  bracketed with a `_Pragma` guard that suppresses the deprecation.
  `_Pragma` (unlike `#pragma`) is not flagged by `R CMD check`’s pragma
  check. The guard is applied by `make r-vendor-deps`
  (`scripts/vendor-guard-json.sh`).

## ppforest2 0.1.1

CRAN release: 2026-07-19

### Packaging and build

- The package now compiles the C++ core directly through `Makevars`
  instead of CMake, with no network access or downloaded dependencies at
  install time. Eigen is provided by RcppEigen; nlohmann/json and pcg
  headers are vendored under `inst/include`. This makes the package
  installable on CRAN’s offline build machines.
- Self-registering strategies are compiled directly into the shared
  object, removing the previous whole-archive linking workaround.
- Compiler flags mirror the standalone C++ build —
  `EIGEN_NO_AUTOMATIC_RESIZING` on all platforms and
  `EIGEN_DONT_VECTORIZE` on Windows.
- Replaced C++20 designated initializers and fixed member-initialization
  order in the vendored core so it compiles warning-free under a strict
  C++17 GCC (`-Wall -Wextra -pedantic`).
- A compile-time `EIGEN_VERSION_AT_LEAST(3, 4, 0)` guard fails the build
  with a clear message if an incompatible Eigen is supplied via
  RcppEigen.
- `make r-vendor-deps` re-vendors the committed json/pcg headers after a
  version bump.

### Documentation

- `DESCRIPTION` uses `Authors@R` and cites the projection-pursuit tree
  and forest references with DOIs.
- Examples for the parsnip and plot methods use `\donttest` with
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) guards
  instead of `\dontrun`, so they run under `--run-donttest` when the
  suggested packages are available.

### CRAN

- Added `cran-comments.md`. The package passes `R CMD check --as-cran`
  with no errors or warnings; remaining notes (new submission, cosmetic
  pragmas in the vendored nlohmann/json headers) are documented for the
  reviewer.

## ppforest2 0.1.0

### New features

- Projection-pursuit oblique decision trees and random forests for
  classification, using LDA/PDA optimization.
- [`pptr()`](https://andres-vidal.github.io/ppforest2-r/reference/pptr.md)
  and
  [`pprf()`](https://andres-vidal.github.io/ppforest2-r/reference/pprf.md)
  with formula and matrix interfaces. Returned models carry an S3 class
  vector identifying both model type and mode
  (e.g. `c("pprf_classification", "pprf", "ppmodel")`).
- [`predict()`](https://rdrr.io/r/stats/predict.html) returns group
  labels (`type = "class"`) or vote proportions (`type = "prob"`) for
  classification.
- Random uniform variable selection per split for forest diversity.
- Three variable importance measures: permuted (VI1), projections (VI2),
  and weighted projections (VI3). Permuted variable importance may be
  negative; this is meaningful signal (“within noise”) rather than a
  sentinel, so callers should rely on the ranking rather than clipping
  at zero. Weighted projection importance is non-negative by
  construction.
- Out-of-bag error and confusion matrix for forests, with bootstrap
  sample indices persisted for recomputation.
- Lazy OOB accessors —
  [`oob_error()`](https://andres-vidal.github.io/ppforest2-r/reference/oob_error.md),
  [`oob_predictions()`](https://andres-vidal.github.io/ppforest2-r/reference/oob_predictions.md),
  [`oob_samples()`](https://andres-vidal.github.io/ppforest2-r/reference/oob_samples.md),
  [`bag_samples()`](https://andres-vidal.github.io/ppforest2-r/reference/bag_samples.md),
  [`permuted_importance()`](https://andres-vidal.github.io/ppforest2-r/reference/permuted_importance.md),
  [`weighted_importance()`](https://andres-vidal.github.io/ppforest2-r/reference/weighted_importance.md)
  — compute from the training data stored on the model on first access
  and memoize in an environment cache, so training is fast and repeated
  access is free.
  [`oob_error()`](https://andres-vidal.github.io/ppforest2-r/reference/oob_error.md)
  is `NA_real_` and
  [`oob_predictions()`](https://andres-vidal.github.io/ppforest2-r/reference/oob_predictions.md)
  returns a factor with `NA` for rows with no OOB tree.
- [`summary()`](https://rdrr.io/r/base/summary.html) displays training
  and OOB confusion matrices.
- Degenerate split detection when projection pursuit cannot find a
  useful projection, surfaced as a warning.
- OpenMP multi-threaded forest training.
- [`save_json()`](https://andres-vidal.github.io/ppforest2-r/reference/save_json.md)
  and
  [`load_json()`](https://andres-vidal.github.io/ppforest2-r/reference/load_json.md)
  for model persistence. Optional metrics fields use a uniform
  `null`-or-value representation so downstream tooling can distinguish
  “computed but empty” from other shapes without special-casing.
- Cross-platform reproducibility — identical results for the same seed
  on Linux, macOS, and Windows, enforced by golden-file tests in CI.
- tidymodels/parsnip integration:
  [`pp_tree()`](https://andres-vidal.github.io/ppforest2-r/reference/pp_tree.md)
  and
  [`pp_rand_forest()`](https://andres-vidal.github.io/ppforest2-r/reference/pp_rand_forest.md)
  model specifications.
- ggplot2 visualizations — tree diagrams, variable importance plots,
  projection histograms, and decision boundary plots.
- Bundled classification datasets: crab, crabs, fishcatch, glass, image,
  leukemia, lymphoma, NCI60, olive, parkinson, and wine. (Use
  [`datasets::iris`](https://rdrr.io/r/datasets/iris.html) from base R
  for iris examples.)

### Experimental features

Regression support is included but untested in production workloads. API
surface and defaults may change in future releases.

- Regression auto-detected when `y` is numeric (not a factor).
  [`predict()`](https://rdrr.io/r/stats/predict.html) returns a numeric
  vector (`type = "response"`).
- Regression strategy wrappers:
  [`grouping_by_cutpoint()`](https://andres-vidal.github.io/ppforest2-r/reference/grouping_by_cutpoint.md),
  [`leaf_mean_response()`](https://andres-vidal.github.io/ppforest2-r/reference/leaf_mean_response.md),
  [`stop_min_size()`](https://andres-vidal.github.io/ppforest2-r/reference/stop_min_size.md),
  [`stop_min_variance()`](https://andres-vidal.github.io/ppforest2-r/reference/stop_min_variance.md),
  [`stop_any()`](https://andres-vidal.github.io/ppforest2-r/reference/stop_any.md).
  Training quantile-slices the continuous response into groups and fits
  mean-response leaves.
- [`summary()`](https://rdrr.io/r/base/summary.html) displays MSE / MAE
  / R² for regression models, computed for training and out-of-bag
  predictions; forest OOB error is reported as MSE.
  [`oob_predictions()`](https://andres-vidal.github.io/ppforest2-r/reference/oob_predictions.md)
  returns a numeric vector with `NA_real_` for rows with no OOB tree.
- [`save_json()`](https://andres-vidal.github.io/ppforest2-r/reference/save_json.md)
  /
  [`load_json()`](https://andres-vidal.github.io/ppforest2-r/reference/load_json.md)
  preserve regression mode; parsnip
  [`pp_tree()`](https://andres-vidal.github.io/ppforest2-r/reference/pp_tree.md)
  /
  [`pp_rand_forest()`](https://andres-vidal.github.io/ppforest2-r/reference/pp_rand_forest.md)
  accept `mode = "regression"`.
- Bundled regression dataset `california_housing` (20,433 × 9, predict
  `median_house_value`). For smaller regression examples use
  [`datasets::mtcars`](https://rdrr.io/r/datasets/mtcars.html) from base
  R.
