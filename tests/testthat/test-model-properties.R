#' @srrstats {RE1.4} The documented assumption that results do not depend on
#'   the units of the features is tested: rescaling and shifting features gives
#'   the same predictions, for LDA and PDA, for trees and forests.
#' @srrstats {RE7.0, RE7.0a} Features with an exact linear relationship are
#'   detected and reported with a warning.
#' @srrstats {RE7.1} A feature exactly proportional to a regression response is
#'   detected and reported with a warning that names it.
#' @srrstats {RE7.1a} Noiseless, perfectly separable classes are fitted with a
#'   single split, so the tree does no more work than for noisy data, which
#'   needs more splits. The number of nodes stands in for fitting time, which
#'   is too variable on shared machines to test directly.
#' @srrstats {RE7.2} The model keeps the row and column names of the training
#'   data, and variable importance and class probabilities are named.
#' @srrstats {RE7.3} The accessors return the documented values, and the
#'   coefficient accessors, which do not apply to trees, return `NULL` or error.
NULL

count_nodes <- function(node) {
  if (!is.null(node$value)) {
    return(1L)
  }
  1L + count_nodes(node$lower) + count_nodes(node$upper)
}

describe("invariance to feature units", {
  x <- as.matrix(iris[, 1:4])
  scaled <- sweep(x, 2, c(8, 0.25, 64, 1), "*")
  shifted <- sweep(x, 2, c(100, -50, 10, 3), "+")

  for (lambda in c(0, 0.5)) {
    it(paste("gives the same tree predictions after rescaling or shifting, lambda =", lambda), {
      model <- pptr(x = x, y = iris$Species, lambda = lambda, seed = 0)
      expect_identical(predict(pptr(x = scaled, y = iris$Species, lambda = lambda, seed = 0), scaled), predict(model, x))
      expect_identical(predict(pptr(x = shifted, y = iris$Species, lambda = lambda, seed = 0), shifted), predict(model, x))
    })

    it(paste("gives the same forest predictions after rescaling, lambda =", lambda), {
      model <- pprf(x = x, y = iris$Species, lambda = lambda, size = 20, seed = 0)
      rescaled <- pprf(x = scaled, y = iris$Species, lambda = lambda, size = 20, seed = 0)
      expect_identical(predict(rescaled, scaled), predict(model, x))
    })
  }
})

describe("noiseless relationships", {
  it("warns about features that are an exact linear function of others", {
    x <- as.matrix(iris[, 1:4])
    x <- cbind(x, combined = x[, 1] + 2 * x[, 2])
    expect_warning(pptr(x = x, y = iris$Species, seed = 0), "perfectly collinear")
  })

  it("warns about a feature proportional to a regression response, naming it", {
    data <- data.frame(x1 = mtcars$mpg * 2, x2 = mtcars$wt, mpg = mtcars$mpg)
    expect_warning(pptr(mpg ~ ., data = data, seed = 0), "collinear with the response: `x1`")
  })

  it("fits noiseless separable classes with a single split", {
    x <- cbind(c(1:10, 21:30), rep(c(0, 1), 10))
    noiseless <- pptr(x = x, y = rep(c("a", "b"), each = 10), seed = 0)
    expect_identical(count_nodes(noiseless$root), 3L)

    noisy <- pptr(x = as.matrix(iris[, 1:4]), y = iris$Species, seed = 0)
    expect_gt(count_nodes(noisy$root), count_nodes(noiseless$root))
  })
})

describe("names in the model", {
  data <- iris
  rownames(data) <- paste0("flower", seq_len(nrow(data)))
  model <- pprf(Species ~ ., data = data, size = 5, seed = 0)

  it("keeps the row and column names of the training data", {
    expect_identical(rownames(model$x), rownames(data))
    expect_identical(colnames(model$x), names(iris)[1:4])
  })

  it("names variable importance by feature and class probabilities by group", {
    expect_identical(names(model$vi$projections), names(iris)[1:4])
    expect_identical(colnames(predict(model, data, type = "prob")), levels(iris$Species))
  })
})

describe("accessors", {
  tree <- pptr(Species ~ ., data = iris, seed = 0)
  regression <- suppressWarnings(pptr(mpg ~ ., data = mtcars, seed = 0))

  it("returns the formula, number of observations, fitted values and residuals", {
    expect_s3_class(formula(tree), "formula")
    expect_null(formula(pptr(x = iris[, 1:4], y = iris$Species, seed = 0)))
    expect_identical(nobs(tree), nrow(iris))
    expect_identical(fitted(tree), predict(tree, iris))
    expect_equal(residuals(regression), mtcars$mpg - predict(regression, mtcars))
  })

  it("has no coefficients, variance-covariance matrix or confidence intervals", {
    expect_null(coef(tree))
    expect_error(vcov(tree), "no applicable method")
    expect_error(confint(tree))
  })
})
