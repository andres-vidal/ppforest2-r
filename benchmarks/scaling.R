# Measures how forest training time grows with the number of observations
# and the number of variables. Run from the repository root:
#
#   Rscript benchmarks/scaling.R
#
# Trains 100-tree forests on simulated two-class data with one thread, doubling
# one dimension at a time, and reports the median elapsed time of three fits
# and the slope of log(time) against log(size), which is the exponent of the
# growth: 1 means time grows linearly with that dimension.

suppressPackageStartupMessages(library(ppforest2))

simulate <- function(n, p) {
  y <- factor(rep(c("a", "b"), length.out = n))
  x <- matrix(stats::rnorm(n * p), nrow = n)
  x[y == "b", 1] <- x[y == "b", 1] + 2
  list(x = x, y = y)
}

median_time <- function(n, p, reps = 3) {
  set.seed(0)
  data <- simulate(n, p)
  stats::median(vapply(seq_len(reps), function(i) {
    system.time(pprf(x = data$x, y = data$y, size = 100, threads = 1, seed = 0))[["elapsed"]]
  }, numeric(1)))
}

sweep <- function(label, sizes, time_for) {
  times <- vapply(sizes, time_for, numeric(1))
  slope <- unname(stats::coef(stats::lm(log(times) ~ log(sizes)))[2])
  cat(sprintf("\n%s (slope of log time on log size: %.2f)\n", label, slope))
  print(data.frame(size = sizes, seconds = round(times, 3)), row.names = FALSE)
}

sweep("Observations, with 8 variables", 2^(9:14), function(n) median_time(n, 8))
sweep("Variables, with 1024 observations", 2^(2:7), function(p) median_time(1024, p))
