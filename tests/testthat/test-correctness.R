#' @srrstats {G5.3} Fitted models and their outputs contain no missing values,
#'   apart from the documented `NA` out-of-bag predictions.
NULL

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
