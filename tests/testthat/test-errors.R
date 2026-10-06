#' @srrstats {G5.2, G5.2a, G5.2b} Every error and warning the package raises is
#'   triggered by a test, here or next to the behaviour it guards, and the
#'   tests match the message. The exceptions are the errors for a missing
#'   suggested package (parsnip, ggplot2, patchwork) and the warning for a
#'   build without OpenMP, which cannot occur where those are available.
NULL

describe("argument errors", {
  it("pptr and pprf reject a formula that is not a formula object", {
    expect_error(pptr("Species ~ .", data = iris), "must be a formula object")
  })

  it("pptr rejects data that is not a data frame", {
    expect_error(pptr(Species ~ ., data = as.matrix(iris)), "must be a data frame")
  })

  it("pptr requires both x and y in the matrix interface", {
    expect_error(pptr(x = iris[, 1:4]), "both `x` and `y` must be provided")
  })

  it("pptr rejects non-numeric features", {
    expect_error(pptr(x = iris[, c(1, 5)], y = iris$Species), "must be numeric")
  })

  it("pptr rejects fewer observations than groups", {
    y <- factor(c("a", "b"), levels = c("a", "b", "c"))
    expect_error(pptr(x = matrix(c(1, 2), ncol = 1), y = y), "at least as many rows as groups")
  })

  it("pprf rejects a negative or non-integer max_retries", {
    expect_error(pprf(Species ~ ., data = iris, max_retries = -1), "`max_retries` must be a non-negative integer")
    expect_error(pprf(Species ~ ., data = iris, max_retries = 1.5), "`max_retries` must be a non-negative integer")
  })
})

describe("predict type errors", {
  tree <- pptr(Species ~ ., data = iris, seed = 0)
  forest <- pprf(Species ~ ., data = iris, size = 5, seed = 0)
  regression_tree <- suppressWarnings(pptr(mpg ~ ., data = mtcars, seed = 0))
  regression_forest <- suppressWarnings(pprf(mpg ~ ., data = mtcars, size = 5, seed = 0))

  it("classification methods reject unsupported types", {
    expect_error(predict(tree, iris, type = "response"), "not supported for classification trees")
    expect_error(predict(forest, iris, type = "response"), "not supported for classification models")
  })

  it("regression methods reject class types and unknown types", {
    expect_error(predict(regression_forest, mtcars, type = "class"), "not available for regression models")
    expect_error(predict(regression_tree, mtcars, type = "other"), "not recognised")
    expect_error(predict(regression_forest, mtcars, type = "other"), "not recognised")
  })

  it("rejects non-numeric new data", {
    expect_error(predict(tree, as.matrix(iris)), "All columns in `new_data` must be numeric")
  })
})

describe("accessor errors", {
  tree <- pptr(Species ~ ., data = iris, seed = 0)

  it("forest-only accessors reject single trees", {
    expect_error(oob_error(tree), "only defined for `pprf` forest models")
    expect_error(oob_predictions(tree), "only defined for `pprf` forest models")
    expect_error(oob_samples(tree), "only defined for `pprf` forest models")
    expect_error(bag_samples(tree), "only defined for `pprf` forest models")
    expect_error(permuted_importance(tree), "only defined for `pprf` forest models")
    expect_error(weighted_importance(tree), "only defined for `pprf` forest models")
  })

  it("explains how to recover training data on a model loaded from JSON", {
    forest <- pprf(Species ~ ., data = iris, size = 5, seed = 0)
    path <- tempfile(fileext = ".json")
    save_json(forest, path, include_metrics = FALSE)
    loaded <- load_json(path)
    expect_error(oob_error(loaded), "re-attach the original training data")
  })

  it("names the missing field on a model without training data or cache", {
    forest <- pprf(Species ~ ., data = iris, size = 5, seed = 0)
    forest$x <- NULL
    forest$.cache <- NULL
    expect_error(oob_error(forest), "Required field `x` is not available on the model")
  })

  it("save_json warns and saves without metrics when the training data is missing", {
    forest <- pprf(Species ~ ., data = iris, size = 5, seed = 0)
    forest$x <- NULL
    expect_warning(save_json(forest, tempfile(fileext = ".json")), "saving without metrics")
  })
})

describe("plotting and tidymodels errors", {
  it("rejects an importance metric the model does not have", {
    skip_if_not_installed("ggplot2")
    tree <- pptr(Species ~ ., data = iris, seed = 0)
    expect_error(ppforest2:::plot_importance(tree, metric = "weighted"), "is not available for this model")
  })

  it("rejects projecting onto a leaf node", {
    skip_if_not_installed("ggplot2")
    tree <- pptr(Species ~ ., data = iris, seed = 0)
    expect_error(ppforest2:::plot_projection(tree, node = 2L), "is a leaf node and has no projector")
  })

  it("rejects update parameters that are not a list or data frame", {
    skip_if_not_installed("parsnip")
    expect_error(update(pp_tree(), parameters = 1), "must be a named list or one-row tibble")
  })
})
