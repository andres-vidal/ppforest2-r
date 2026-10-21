# Shared setup for benchmarks/speed.R and benchmarks/memory.R: the data
# generator, how each package trains a forest, and the experiments.
#
# The experiments reproduce, at a smaller scale, those behind the performance
# results of Vidal (2026), the thesis that evaluates ppforest2 against PPforest.
# Each varies one parameter and fixes the rest. The grids start where the two
# implementations begin to differ and stop at sizes that run on a laptop, and
# forests have fewer trees than in the thesis, so the shape of each result is
# reproduced but not its magnitudes.

suppressPackageStartupMessages({
  library(MASS)
  library(ppforest2)
  library(PPforest)
})

# `q` groups of ceiling(n / q) observations in `p` variables, each normal with
# a random mean and covariance. The generator used in the thesis.
simulate <- function(n, p, q) {
  per_group <- ceiling(n / q)
  data <- NULL
  for (i in seq_len(q)) {
    mean <- stats::rnorm(p, 100 * i, 25)
    covariance <- matrix(stats::rnorm(p^2, 0, 25), nrow = p)
    covariance <- t(covariance) %*% covariance
    group <- cbind(MASS::mvrnorm(per_group, mean, covariance), i)
    data <- rbind(data, group)
  }
  colnames(data) <- c(paste0("V", seq_len(p)), "Type")
  data <- as.data.frame(data)
  data$Type <- factor(data$Type)
  data
}

# PPforest rounds `size.p * p` half away from zero to get the number of
# variables per split; ppforest2 is given the same count.
round_half_away <- function(x) floor(x + ifelse(x < 0, -0.5, 0.5))

# Trains a forest with PPforest ("og") or ppforest2 ("nw"). PPforest runs its
# trees in forked processes when `threads` > 1. PPforest 0.2.0 renamed the
# response argument from `class` to `y`, and takes `std` as a method name.
train <- function(version, data, lambda, pvars, size, threads) {
  p <- ncol(data) - 1
  switch(version,
    og = {
      args <- list(
        data = data, m = size, PPmethod = if (lambda == 0) "LDA" else "PDA",
        lambda = lambda, size.p = pvars, size.tr = 1, rule = 1,
        parallel = threads > 1, cores = threads
      )
      if (utils::packageVersion("PPforest") >= "0.2.0") {
        args <- c(args, y = "Type", std = "no")
      } else {
        args <- c(args, class = "Type", std = FALSE)
      }
      do.call(PPforest::PPforest, args)
    },
    nw = ppforest2::pprf(
      Type ~ ., data = data, size = size, lambda = lambda, threads = threads,
      n_vars = round_half_away(p * pvars), seed = 0
    )
  )
}

cores <- parallel::detectCores()
thread_counts <- unique(c(1, 2, 4, 8, cores)[c(1, 2, 4, 8, cores) <= cores])

# One list per experiment, in the thesis's naming: `n`, `p`, `q`, `lambda`,
# `pvars`, `size` and `threads` hold the values to run, and exactly one of them
# varies.
experiments <- list(
  # Size sweeps, with all cores.
  n     = list(n = c(1024, 2048, 4096, 8192), p = 4, q = 2, lambda = 0.5, pvars = 1, size = 100, threads = cores),
  p     = list(n = 32, p = c(64, 128, 256, 512), q = 2, lambda = 0.5, pvars = 1, size = 100, threads = cores),
  p_v05 = list(n = 32, p = c(64, 128, 256, 512), q = 2, lambda = 0.5, pvars = 0.5, size = 100, threads = cores),
  q     = list(n = 2048, p = 4, q = c(16, 32, 64, 128), lambda = 0.5, pvars = 1, size = 100, threads = cores),
  l     = list(n = 512, p = 8, q = 8, lambda = c(0, 0.1, 0.5, 1), pvars = 1, size = 100, threads = cores),
  v     = list(n = 512, p = 32, q = 4, lambda = 0.5, pvars = c(0.25, 0.5, 0.75, 1), size = 100, threads = cores),
  f     = list(n = 128, p = 8, q = 4, lambda = 0.5, pvars = 1, size = c(100, 300, 500, 1000), threads = cores),
  # Thread sweeps: one dimension large, the others moderate.
  t_n   = list(n = 8192, p = 16, q = 4, lambda = 0.5, pvars = 1, size = 200, threads = thread_counts),
  t_p   = list(n = 1024, p = 128, q = 4, lambda = 0.5, pvars = 1, size = 200, threads = thread_counts),
  t_q   = list(n = 1024, p = 16, q = 16, lambda = 0.5, pvars = 1, size = 200, threads = thread_counts),
  # Serial sweeps: one thread, which isolates the algorithms from parallelism.
  s_n   = list(n = c(1024, 2048, 4096), p = 4, q = 2, lambda = 0.5, pvars = 1, size = 100, threads = 1),
  s_p   = list(n = 32, p = c(64, 128, 256), q = 2, lambda = 0.5, pvars = 1, size = 100, threads = 1),
  s_q   = list(n = 2048, p = 4, q = c(16, 32, 64), lambda = 0.5, pvars = 1, size = 100, threads = 1)
)

# Repeats `measure()` until its results are stable, with the rule of the
# ppforest2-core benchmark runner: after at least `min` runs, the coefficient
# of variation of all the runs (their standard deviation over their mean) must
# stay below `cv` for `window` consecutive runs. It stops unconverged after
# `max` runs or once `budget` seconds have passed. Returns the measurements and
# whether they converged.
converge <- function(measure, cv = 0.05, window = 3, min = 5, max = 30, budget = 120) {
  values <- numeric(0)
  stable <- 0
  start <- Sys.time()
  repeat {
    values <- c(values, measure())
    if (length(values) >= min) {
      center <- mean(values)
      stable <- if (center <= 0 || stats::sd(values) / center < cv) stable + 1 else 0
    }
    if (stable >= window) {
      return(list(values = values, converged = TRUE))
    }
    elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))
    if (length(values) >= max || elapsed > budget) {
      return(list(values = values, converged = FALSE))
    }
  }
}

# The cells of an experiment: one row per combination of its values.
cells <- function(experiment) {
  expand.grid(experiment[c("n", "p", "q", "lambda", "pvars", "size", "threads")], KEEP.OUT.ATTRS = FALSE)
}

# The experiments named on the command line, or all of them.
selected_experiments <- function(args) {
  if (length(args) == 0) return(experiments)
  unknown <- setdiff(args, names(experiments))
  if (length(unknown) > 0) stop("Unknown experiments: ", paste(unknown, collapse = ", "))
  experiments[args]
}

# Writes the machine and the package versions a run used to
# benchmarks/results/<name>-environment.txt, next to its results.
write_environment <- function(name) {
  linux <- Sys.info()[["sysname"]] == "Linux"
  if (linux) {
    cpu <- sub(".*:\\s*", "", grep("^model name", readLines("/proc/cpuinfo"), value = TRUE)[1])
    memory <- as.numeric(gsub("\\D", "", grep("^MemTotal", readLines("/proc/meminfo"), value = TRUE))) * 2^10
  } else {
    cpu <- system2("sysctl", c("-n", "machdep.cpu.brand_string"), stdout = TRUE)
    memory <- as.numeric(system2("sysctl", c("-n", "hw.memsize"), stdout = TRUE))
  }
  package <- function(name) {
    description <- utils::packageDescription(name)
    sha <- description$RemoteSha
    paste0(description$Version, if (!is.null(sha)) paste0(" (", substr(sha, 1, 7), ")"))
  }
  lines <- c(
    paste("Date:", format(Sys.Date())),
    paste("CPU:", cpu),
    paste("Cores:", cores),
    paste("Memory:", round(memory / 2^30), "GB"),
    paste("OS:", utils::osVersion),
    paste("R:", R.version.string),
    paste("BLAS:", utils::sessionInfo()$BLAS),
    paste("PPforest:", package("PPforest")),
    paste("ppforest2:", package("ppforest2"))
  )
  dir.create("benchmarks/results", showWarnings = FALSE)
  writeLines(lines, file.path("benchmarks/results", paste0(name, "-environment.txt")))
}
