# Compares forest training time with PPforest, the previous R implementation
# of the method, on simulated data. Run from the repository root:
#
#   Rscript benchmarks/compare-ppforest.R
#
# Requires ppforest2 and PPforest to be installed. Both packages train forests
# of the same size, with the same PDA lambda and the same number of variables
# per split, on the same data, with one thread and with all available threads.
# Each fit is repeated and the median elapsed time is reported.

suppressPackageStartupMessages({
  library(ppforest2)
  library(PPforest)
})

# PPforest rounds `size.p * p` half away from zero to get the number of
# variables per split; the same count is passed to ppforest2 as `n_vars`.
round_half_away <- function(x) floor(x + ifelse(x < 0, -0.5, 0.5))

# `q` classes in `p` dimensions, with class means drawn at random and unit
# within-class variance.
simulate <- function(n, p, q) {
  y <- factor(rep(seq_len(q), length.out = n))
  means <- matrix(stats::rnorm(q * p, sd = 2), nrow = q)
  x <- means[as.integer(y), , drop = FALSE] + matrix(stats::rnorm(n * p), nrow = n)
  data <- as.data.frame(x)
  data$Type <- y
  data
}

median_time <- function(fit, reps) {
  stats::median(vapply(seq_len(reps), function(i) system.time(fit())[["elapsed"]], numeric(1)))
}

scenarios <- expand.grid(n = c(500, 2000), p = c(4, 32), q = c(2, 4))
size <- 100
lambda <- 0.5
p_vars <- 0.5
reps <- 3
threads <- unique(c(1, parallel::detectCores()))

results <- list()
for (i in seq_len(nrow(scenarios))) {
  scenario <- scenarios[i, ]
  set.seed(0)
  data <- simulate(scenario$n, scenario$p, scenario$q)
  n_vars <- round_half_away(scenario$p * p_vars)

  for (t in threads) {
    ppforest_time <- median_time(function() {
      PPforest::PPforest(
        data = data, class = "Type", m = size, PPmethod = "PDA", lambda = lambda,
        size.p = p_vars, size.tr = 1, std = FALSE, rule = 1,
        parallel = t > 1, cores = t
      )
    }, reps)

    ppforest2_time <- median_time(function() {
      pprf(Type ~ ., data = data, size = size, lambda = lambda, n_vars = n_vars, threads = t, seed = 0)
    }, reps)

    results[[length(results) + 1]] <- data.frame(
      scenario,
      threads = t,
      PPforest = ppforest_time,
      ppforest2 = ppforest2_time,
      speedup = ppforest_time / ppforest2_time
    )
  }
}

print(do.call(rbind, results), digits = 3, row.names = FALSE)
