#' @srrstats {G5.4b} Single trees are compared with the previous implementation,
#'   `PPforest::PPtree_split()`: the root projection has the same direction and
#'   every prediction agrees, on five datasets, for LDA and PDA.
#' @srrstats {G5.6, G5.6a, G5.6b} Parameter recovery: on simulated data whose
#'   classes differ along a known direction, the root projector recovers that
#'   direction within tolerance, for several random datasets.
#' @srrstats {G5.7} Algorithm performance: the test error falls as the classes
#'   are separated further.
#' @srrstats {G5.9, G5.9a, G5.9b} Noise susceptibility: noise at machine
#'   precision leaves the model unchanged, and forests trained with different
#'   seeds reach similar accuracy and agree on most predictions.
#' @srrstats {G5.3} Fitted models and their outputs contain no missing values,
#'   apart from the documented `NA` out-of-bag predictions.
#' @srrstats {G5.8, G5.8c, G5.8d} Edge cases: an all-`NA` column is rejected,
#'   and data with more variables than observations trains with the default
#'   PDA index.
NULL

# Two classes in `p` dimensions whose means differ by `delta` along `direction`,
# with identity within-class covariance. The LDA direction is `direction`.
simulate_two_classes <- function(n_per_class, p, delta, direction) {
  direction <- direction / sqrt(sum(direction^2))
  x <- matrix(stats::rnorm(2 * n_per_class * p), ncol = p)
  y <- rep(c("a", "b"), each = n_per_class)
  x[y == "b", ] <- sweep(x[y == "b", , drop = FALSE], 2, delta * direction, "+")
  list(x = x, y = y)
}

cosine <- function(a, b) abs(sum(a * b)) / sqrt(sum(a^2) * sum(b^2))

describe("correctness against PPforest", {
  skip_if_not_installed("PPforest")

  datasets <- list(
    iris = stats::setNames(datasets::iris, c(names(datasets::iris)[1:4], "Type")),
    crab = ppforest2::crab,
    wine = ppforest2::wine,
    glass = ppforest2::glass,
    fishcatch = ppforest2::fishcatch
  )

  for (name in names(datasets)) {
    for (lambda in c(0, 0.5)) {
      it(paste("matches PPtree_split on", name, "with lambda =", lambda), {
        data <- datasets[[name]]
        data$Type <- factor(data$Type)
        features <- setdiff(names(data), "Type")

        method <- if (lambda == 0) "LDA" else "PDA"
        original <- PPforest::PPtree_split("Type ~ .", data, PPmethod = method, size.p = 1, lambda = lambda)
        model <- pptr(Type ~ ., data = data, lambda = lambda, seed = 0)

        expect_gt(cosine(original$projbest.node[1, ], model$root$projector), 1 - 1e-6)

        index <- PPforest::PPclassify2(original, test.data = data[, features], Rule = 1)$predict.class[, 1]
        expect_identical(as.character(predict(model, data)), levels(data$Type)[index])
      })
    }
  }
})

describe("parameter recovery", {
  skip_if_not_installed("withr")

  it("recovers the separating direction within tolerance for several datasets", {
    direction <- c(1, 1, 0, 0)
    for (seed in 0:4) {
      sim <- withr::with_seed(seed, simulate_two_classes(100, 4, delta = 4, direction = direction))
      model <- pptr(x = sim$x, y = sim$y, seed = 0)
      expect_gt(cosine(model$root$projector, direction), 0.95)
    }
  })
})

describe("algorithm performance", {
  skip_if_not_installed("withr")

  it("has lower test error when the classes are further apart", {
    direction <- c(1, 0, 0, 0)
    errors <- vapply(c(0.5, 1, 2, 4), function(delta) {
      train <- withr::with_seed(1, simulate_two_classes(100, 4, delta, direction))
      test <- withr::with_seed(2, simulate_two_classes(500, 4, delta, direction))
      model <- pptr(x = train$x, y = train$y, seed = 0)
      mean(as.character(predict(model, test$x)) != test$y)
    }, numeric(1))

    expect_true(all(diff(errors) <= 0.02))
    expect_lt(errors[4], errors[1])
  })
})

describe("noise susceptibility", {
  it("gives the same model when noise at machine precision is added", {
    x <- as.matrix(iris[, 1:4])
    noisy <- x * (1 + .Machine$double.eps)
    model <- pptr(x = x, y = iris$Species, seed = 0)
    noisy_model <- pptr(x = noisy, y = iris$Species, seed = 0)

    expect_equal(noisy_model$root$projector, model$root$projector)
    expect_identical(predict(noisy_model, x), predict(model, x))
  })

  it("reaches similar results with different seeds", {
    models <- lapply(0:4, function(seed) pprf(Species ~ ., data = iris, size = 50, seed = seed))
    oob <- vapply(models, oob_error, numeric(1))
    expect_true(all(oob < 0.1))

    reference <- predict(models[[1]], iris)
    for (model in models[-1]) {
      expect_gt(mean(predict(model, iris) == reference), 0.95)
    }
  })
})

describe("return values", {
  it("contain no missing values for a classification forest", {
    model <- pprf(Species ~ ., data = iris, size = 50, seed = 0)
    expect_false(anyNA(predict(model, iris)))
    expect_false(anyNA(as.matrix(predict(model, iris, type = "prob"))))
    expect_false(anyNA(model$vi$scale))
    expect_false(anyNA(model$vi$projections))
    expect_false(anyNA(weighted_importance(model)))
    expect_false(anyNA(permuted_importance(model)))
    expect_false(is.na(oob_error(model)))
  })

  it("contain no missing values for a regression forest", {
    model <- pprf(mpg ~ ., data = mtcars, size = 50, seed = 0)
    predictions <- predict(model, mtcars)
    expect_true(all(is.finite(predictions)))
    expect_false(anyNA(model$vi$projections))
    expect_false(is.na(oob_error(model)))
  })
})

describe("edge cases", {
  it("rejects a column of missing values", {
    x <- cbind(as.matrix(iris[, 1:4]), missing = NA_real_)
    expect_error(pptr(x = x, y = iris$Species), "NA or NaN")
  })

  it("trains with more variables than observations using the default PDA index", {
    skip_if_not_installed("withr")
    sim <- withr::with_seed(0, simulate_two_classes(10, 50, delta = 6, direction = c(1, rep(0, 49))))
    model <- pptr(x = sim$x, y = sim$y, seed = 0)
    expect_length(predict(model, sim$x), 20)
  })
})
