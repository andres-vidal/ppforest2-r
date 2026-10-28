# Training time of PPforest and ppforest2, by experiment. Run from the
# repository root, with both packages installed:
#
#   Rscript benchmarks/speed.R            # every experiment
#   Rscript benchmarks/speed.R n q t_n    # some of them
#
# The experiments are defined in benchmarks/common.R. Each cell is simulated
# once with a fixed seed, and each implementation fits it until the elapsed
# times converge (see `converge()` in common.R); the mean time is reported,
# with the number of fits and a mark for cells that did not converge. Size
# sweeps print both times and their ratio; thread sweeps print each
# implementation's speedup T(1) / T(t). The results are also written to
# benchmarks/results/speed.csv, and the machine and package versions to
# benchmarks/results/speed-environment.txt.

source("benchmarks/common.R")

time_fits <- function(version, data, cell) {
  converge(function() {
    system.time(train(version, data, cell$lambda, cell$pvars, cell$size, cell$threads))[["elapsed"]]
  })
}

run_experiment <- function(name, experiment) {
  grid <- cells(experiment)
  rows <- lapply(seq_len(nrow(grid)), function(i) {
    cell <- grid[i, ]
    set.seed(0)
    data <- simulate(cell$n, cell$p, cell$q)
    og <- suppressWarnings(time_fits("og", data, cell))
    nw <- suppressWarnings(time_fits("nw", data, cell))
    data.frame(
      experiment = name, cell,
      PPforest = mean(og$values), PPforest_fits = length(og$values), PPforest_converged = og$converged,
      ppforest2 = mean(nw$values), ppforest2_fits = length(nw$values), ppforest2_converged = nw$converged
    )
  })
  do.call(rbind, rows)
}

report <- function(name, result, experiment) {
  varying <- names(which(lengths(experiment[c("n", "p", "q", "lambda", "pvars", "size", "threads")]) > 1))
  mark <- function(fits, converged) paste0(fits, ifelse(converged, "", "*"))
  shown <- result[, c(varying, "PPforest", "ppforest2")]
  shown$fits <- paste(mark(result$PPforest_fits, result$PPforest_converged),
                      mark(result$ppforest2_fits, result$ppforest2_converged), sep = "/")
  if (identical(varying, "threads")) {
    shown$PPforest_speedup <- result$PPforest[1] / result$PPforest
    shown$ppforest2_speedup <- result$ppforest2[1] / result$ppforest2
  } else {
    shown$ratio <- result$PPforest / result$ppforest2
  }
  fixed <- experiment[setdiff(c("n", "p", "q", "lambda", "pvars", "size", "threads"), varying)]
  cat(sprintf("\n%s (%s)\n", name, paste(names(fixed), unlist(fixed), sep = " = ", collapse = ", ")))
  print(shown, digits = 3, row.names = FALSE)
  cat("fits: number of PPforest/ppforest2 fits; * marks a cell that did not converge\n")
}

results <- list()
chosen <- selected_experiments(commandArgs(trailingOnly = TRUE))
for (name in names(chosen)) {
  results[[name]] <- run_experiment(name, chosen[[name]])
  report(name, results[[name]], chosen[[name]])
}

dir.create("benchmarks/results", showWarnings = FALSE)
utils::write.csv(do.call(rbind, results), "benchmarks/results/speed.csv", row.names = FALSE)
write_environment("speed")
