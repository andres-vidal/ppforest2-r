# Package index

## Models

- [`pptr()`](https://andres-vidal.github.io/ppforest2-r/reference/pptr.md)
  : Trains a Projection-Pursuit oblique decision tree.
- [`pprf()`](https://andres-vidal.github.io/ppforest2-r/reference/pprf.md)
  : Trains a Random Forest of Projection-Pursuit oblique decision trees.

## Prediction and fitted values

- [`predict(`*`<pprf_classification>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/predict.pprf_classification.md)
  : Predicts labels or vote proportions from a pprf model
  (classification mode).
- [`predict(`*`<pprf_regression>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/predict.pprf_regression.md)
  : Predicts numeric responses from a pprf model (regression mode).
- [`predict(`*`<pptr_classification>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/predict.pptr_classification.md)
  : Predicts labels or per-group one-hot proportions from a pptr model
  (classification mode).
- [`predict(`*`<pptr_regression>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/predict.pptr_regression.md)
  : Predicts numeric responses from a pptr model (regression mode).
- [`fitted(`*`<ppmodel>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/fitted.ppmodel.md)
  : Fitted (in-sample) predictions from a ppforest2 model.
- [`residuals(`*`<ppmodel>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/residuals.ppmodel.md)
  : Residuals from a regression ppforest2 model.
- [`nobs(`*`<ppmodel>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/nobs.ppmodel.md)
  : Number of observations used to fit a ppforest2 model.
- [`formula(`*`<ppmodel>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/formula.ppmodel.md)
  : Formula extractor for ppforest2 models.

## Printing and summaries

- [`print(`*`<pptr>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/print.pptr.md)
  : Prints the structure of a pptr tree.
- [`print(`*`<pprf>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/print.pprf.md)
  : Prints a compact summary of a pprf forest.
- [`summary(`*`<pprf>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/summary.pprf.md)
  : Summary of a pprf forest (shared header + VI).

## Out-of-bag results

- [`oob_error()`](https://andres-vidal.github.io/ppforest2-r/reference/oob_error.md)
  : Out-of-bag error for a random forest.
- [`oob_predictions()`](https://andres-vidal.github.io/ppforest2-r/reference/oob_predictions.md)
  : Out-of-bag predictions for a random forest.
- [`oob_samples()`](https://andres-vidal.github.io/ppforest2-r/reference/oob_samples.md)
  : Out-of-bag row indices per tree.
- [`bag_samples()`](https://andres-vidal.github.io/ppforest2-r/reference/bag_samples.md)
  : In-bag row indices per tree.

## Variable importance

- [`projection_importance()`](https://andres-vidal.github.io/ppforest2-r/reference/projection_importance.md)
  : Projection-coefficient variable importance.
- [`weighted_importance()`](https://andres-vidal.github.io/ppforest2-r/reference/weighted_importance.md)
  : Weighted projection variable importance for a random forest.
- [`permuted_importance()`](https://andres-vidal.github.io/ppforest2-r/reference/permuted_importance.md)
  : Permuted variable importance for a random forest.

## Plotting

- [`plot(`*`<pptr>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/plot.pptr.md)
  : Plot a pptr model.
- [`plot(`*`<pprf>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/plot.pprf.md)
  : Plot a pprf model.

## Training strategies

Each step of node training is a strategy that can be replaced. See
[`vignette("custom-strategies")`](https://andres-vidal.github.io/ppforest2-r/articles/custom-strategies.md).

- [`pp_pda()`](https://andres-vidal.github.io/ppforest2-r/reference/pp_pda.md)
  : PDA projection pursuit strategy.
- [`vars_all()`](https://andres-vidal.github.io/ppforest2-r/reference/vars_all.md)
  : All-variables selection strategy.
- [`vars_uniform()`](https://andres-vidal.github.io/ppforest2-r/reference/vars_uniform.md)
  : Uniform random variable selection strategy.
- [`cutpoint_mean_of_means()`](https://andres-vidal.github.io/ppforest2-r/reference/cutpoint_mean_of_means.md)
  : Mean-of-means split cutpoint strategy.
- [`stop_any()`](https://andres-vidal.github.io/ppforest2-r/reference/stop_any.md)
  : Composite stopping rule (logical OR).
- [`stop_max_depth()`](https://andres-vidal.github.io/ppforest2-r/reference/stop_max_depth.md)
  : Maximum-depth stopping rule.
- [`stop_min_size()`](https://andres-vidal.github.io/ppforest2-r/reference/stop_min_size.md)
  : Minimum-size stopping rule.
- [`stop_min_variance()`](https://andres-vidal.github.io/ppforest2-r/reference/stop_min_variance.md)
  : Minimum-variance stopping rule.
- [`stop_pure_node()`](https://andres-vidal.github.io/ppforest2-r/reference/stop_pure_node.md)
  : Pure-node stopping rule.
- [`binarize_disabled()`](https://andres-vidal.github.io/ppforest2-r/reference/binarize_disabled.md)
  : Disabled binarization strategy (placeholder).
- [`binarize_largest_gap()`](https://andres-vidal.github.io/ppforest2-r/reference/binarize_largest_gap.md)
  : Largest-gap binarization strategy.
- [`grouping_by_cutpoint()`](https://andres-vidal.github.io/ppforest2-r/reference/grouping_by_cutpoint.md)
  : Cutpoint-based grouping strategy (regression).
- [`grouping_by_label()`](https://andres-vidal.github.io/ppforest2-r/reference/grouping_by_label.md)
  : Label-based grouping strategy.
- [`leaf_majority_vote()`](https://andres-vidal.github.io/ppforest2-r/reference/leaf_majority_vote.md)
  : Majority-vote leaf strategy.
- [`leaf_mean_response()`](https://andres-vidal.github.io/ppforest2-r/reference/leaf_mean_response.md)
  : Mean-response leaf strategy.

## tidymodels integration

- [`pp_tree()`](https://andres-vidal.github.io/ppforest2-r/reference/pp_tree.md)
  : Parsnip model specification for pptr.

- [`pp_rand_forest()`](https://andres-vidal.github.io/ppforest2-r/reference/pp_rand_forest.md)
  : Parsnip model specification for pprf.

- [`update(`*`<pp_tree>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/update.pp_tree.md)
  :

  Update a `pp_tree` model specification.

- [`update(`*`<pp_rand_forest>`*`)`](https://andres-vidal.github.io/ppforest2-r/reference/update.pp_rand_forest.md)
  :

  Update a `pp_rand_forest` model specification.

## Saving and loading models

- [`save_json()`](https://andres-vidal.github.io/ppforest2-r/reference/save_json.md)
  : Save a model to a JSON file.
- [`load_json()`](https://andres-vidal.github.io/ppforest2-r/reference/load_json.md)
  : Load a model from a JSON file.

## Datasets

- [`california_housing`](https://andres-vidal.github.io/ppforest2-r/reference/california_housing.md)
  : California Housing Dataset
- [`crab`](https://andres-vidal.github.io/ppforest2-r/reference/crab.md)
  : Australian Crabs Dataset
- [`crabs`](https://andres-vidal.github.io/ppforest2-r/reference/crabs.md)
  : Crabs Dataset
- [`fishcatch`](https://andres-vidal.github.io/ppforest2-r/reference/fishcatch.md)
  : Fish Catch Dataset
- [`glass`](https://andres-vidal.github.io/ppforest2-r/reference/glass.md)
  : Glass Dataset
- [`image`](https://andres-vidal.github.io/ppforest2-r/reference/image.md)
  : Image Dataset
- [`leukemia`](https://andres-vidal.github.io/ppforest2-r/reference/leukemia.md)
  : Leukemia Dataset
- [`lymphoma`](https://andres-vidal.github.io/ppforest2-r/reference/lymphoma.md)
  : Lymphoma Dataset
- [`NCI60`](https://andres-vidal.github.io/ppforest2-r/reference/NCI60.md)
  : NCI60 Dataset
- [`olive`](https://andres-vidal.github.io/ppforest2-r/reference/olive.md)
  : Olive Dataset
- [`parkinson`](https://andres-vidal.github.io/ppforest2-r/reference/parkinson.md)
  : Parkinson Dataset
- [`wine`](https://andres-vidal.github.io/ppforest2-r/reference/wine.md)
  : Wine Dataset
