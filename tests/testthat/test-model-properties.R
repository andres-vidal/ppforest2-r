#' @srrstats {RE1.4} The documented assumption that results do not depend on
#'   the units of the features is tested: rescaling and shifting features gives
#'   the same predictions, for LDA and PDA, for trees and forests.
NULL

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
