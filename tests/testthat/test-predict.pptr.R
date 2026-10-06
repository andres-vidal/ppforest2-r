Sys.setenv(R_TESTS = "")
Sys.setenv(OMP_THREAD_LIMIT = "1")
Sys.setenv(OMP_NUM_THREADS = "1")

library(testthat)
library(ppforest2)

describe("predict.pptr", {
  describe("on an object created with the formula interface", {
    it("returns a factor with the same length as the input matrix", {
      model <- pptr(Species ~ ., data = iris)
      predictions <- predict(model, iris)
      expect_equal(length(predictions), nrow(iris))
    })

    it("returns a factor with the same levels as the groups in the model", {
      model <- pptr(Species ~ ., data = iris)
      predictions <- predict(model, iris)
      expect_equal(levels(predictions), levels(iris$Species))
    })

    it("with new_data parameter returns the same result as positional", {
      model <- pptr(Species ~ ., data = iris)
      pred_positional <- predict(model, iris)
      pred_named <- predict(model, new_data = iris)
      expect_equal(pred_positional, pred_named)
    })
  })

  describe("on an object created with the matrix interface", {
    it("returns a factor with the same length as the input matrix", {
      x <- crabs[, 2:5]
      x$sex <- as.numeric(as.factor(crabs$sex))
      model <- pptr(x = x, y = crabs$Type)
      predictions <- predict(model, x)
      expect_equal(length(predictions), nrow(x))
    })

    it("returns a factor with the same levels as the groups in the model", {
      x <- crabs[, 2:5]
      x$sex <- as.numeric(as.factor(crabs$sex))
      model <- pptr(x = x, y = crabs$Type)
      predictions <- predict(model, x)
      expect_equal(levels(predictions), levels(crabs$Type))
    })
  })

  describe("with type = 'prob'", {
    it("returns a data frame with one column per group", {
      model <- pptr(Species ~ ., data = iris)
      probs <- predict(model, iris, type = "prob")
      expect_true(is.data.frame(probs))
      expect_equal(ncol(probs), length(levels(iris$Species)))
      expect_equal(colnames(probs), levels(iris$Species))
    })

    it("returns exactly one 1.0 per row and the rest 0.0", {
      model <- pptr(Species ~ ., data = iris)
      probs <- predict(model, iris, type = "prob")
      row_sums <- rowSums(probs)
      expect_equal(row_sums, rep(1.0, nrow(iris)))
      expect_true(all(probs == 0 | probs == 1))
    })

    it("the 1.0 column matches the group prediction", {
      model <- pptr(Species ~ ., data = iris)
      group_preds <- predict(model, iris, type = "class")
      prob_preds <- predict(model, iris, type = "prob")
      for (i in seq_len(nrow(iris))) {
        expect_equal(prob_preds[i, as.character(group_preds[i])], 1.0)
      }
    })
  })
})

describe("predict.pptr input validation", {
  model <- pptr(Species ~ ., data = iris, seed = 0)

  it("rejects new data with a different number of features", {
    expect_error(predict(model, as.matrix(iris[1:3, 1:3])), "3 columns, but the model was trained on 4")
  })

  it("rejects NA in new data instead of dropping the row", {
    new_data <- iris[1:5, ]
    new_data[2, 1] <- NA
    expect_error(predict(model, new_data), "NA or NaN")
  })

  it("rejects Inf in new data", {
    new_data <- as.matrix(iris[1:3, 1:4])
    new_data[1, 1] <- Inf
    expect_error(predict(model, new_data), "finite")
  })

  it("accepts a data frame without the response column", {
    expect_identical(predict(model, iris[1:5, 1:4]), predict(model, iris[1:5, ]))
  })

  it("rejects a type that is not a single string", {
    expect_error(predict(model, iris, type = c("class", "prob")), "single character string")
  })

  it("keeps every group as a level when only some are predicted", {
    predictions <- predict(model, iris[1:3, ])
    expect_identical(levels(predictions), levels(iris$Species))
  })

  it("checks the feature count of a model loaded without training data", {
    path <- tempfile(fileext = ".json")
    save_json(model, path)
    loaded <- load_json(path)
    expect_error(predict(loaded, as.matrix(iris[1:3, 1:3])), "trained on 4")
  })
})
