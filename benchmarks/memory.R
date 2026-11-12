# Peak memory of PPforest and ppforest2, by experiment. Run from the
# repository root, on macOS or Linux, with both packages installed:
#
#   Rscript benchmarks/memory.R            # every experiment
#   Rscript benchmarks/memory.R n q t_n    # some of them
#
# Each fit runs in its own R process (benchmarks/memory-fit.R), and the peak
# memory of that process and every process it starts is measured. A "dry"
# process that loads the packages and simulates the same data without
# training is measured too, and subtracted, so the figures are the memory the
# training itself adds. Each process is repeated until its peaks converge (see
# `converge()` in common.R), and the means are subtracted.
#
# The process tree matters because the two packages parallelize differently:
# ppforest2 trains its trees in threads of one process, while PPforest forks
# worker processes that share the parent's memory until they write to it.
# Shared pages must be counted once, which only Linux allows without
# privileges, so the measurement depends on the platform:
#
#   * On Linux with systemd and cgroup v2, each process tree runs in its own
#     transient cgroup (systemd-run --user --scope), and the kernel's
#     memory.peak for that cgroup is read. Every page is counted once,
#     whichever process uses it.
#   * On other Linux systems, the tree is sampled every `interval` seconds,
#     and its memory is the sum of the proportional set size of its
#     processes, which splits each shared page among the processes that use
#     it.
#   * On macOS, the memory a worker shares with its parent cannot be told
#     apart from its own, so only single processes are measured: the size
#     sweeps run with one thread for both packages, and the thread sweeps
#     measure ppforest2 alone. The resident set size of the process is
#     sampled every `interval` seconds.
#
# Sampled peaks can miss a spike shorter than `interval`. The results are
# also written to benchmarks/results/memory.csv, with the method used, and the
# machine and package versions to benchmarks/results/memory-environment.txt.

source("benchmarks/common.R")

rscript <- file.path(R.home("bin"), "Rscript")
interval <- 0.02

fit_args <- function(version, cell) {
  c("benchmarks/memory-fit.R", version, cell$n, cell$p, cell$q, cell$lambda, cell$pvars, cell$size, cell$threads)
}

linux <- Sys.info()[["sysname"]] == "Linux"
cgroups <- linux && nzchar(Sys.which("systemd-run")) && file.exists("/sys/fs/cgroup/cgroup.controllers")
method <- if (cgroups) "cgroup memory.peak" else if (linux) "sampled PSS" else "sampled RSS, one process"
whole_tree <- linux

# Peak memory, in MB, of the cgroup the fit runs in, read from inside the
# transient scope before it is removed.
peak_mb_cgroup <- function(version, cell) {
  peak_file <- tempfile()
  on.exit(unlink(peak_file))
  command <- paste(
    paste(shQuote(c(rscript, fit_args(version, cell))), collapse = " "), "> /dev/null 2>&1;",
    "status=$?;",
    "group=$(head -1 /proc/self/cgroup | cut -d: -f3);",
    "cat /sys/fs/cgroup$group/memory.peak >", shQuote(peak_file), ";",
    "exit $status"
  )
  status <- system2("systemd-run", c("--user", "--scope", "--quiet", "--property=MemoryAccounting=yes",
                                     "--", "bash", "-c", shQuote(command)))
  if (status != 0) stop("The ", version, " fit failed in its cgroup (exit status ", status, ").")
  as.numeric(readLines(peak_file, warn = FALSE)) / 2^20
}

# The processes the fit started, listed again when one exits while they are
# being listed, which is frequent while PPforest's workers come and go. NULL
# if the list cannot be read.
children_of <- function(root, attempts = 5) {
  for (i in seq_len(attempts)) {
    children <- tryCatch(ps::ps_children(root, recursive = TRUE), error = function(e) NULL)
    if (!is.null(children)) return(children)
  }
  NULL
}

# Memory, in bytes, of a process tree: the proportional set size of its root
# and every descendant, or NA if the descendants cannot be listed. A
# descendant that exits while it is being read is skipped.
tree_pss <- function(root) {
  children <- children_of(root)
  if (is.null(children)) return(NA_real_)
  total <- ps::ps_memory_full_info(root)[["pss"]]
  for (child in children) {
    total <- total + tryCatch(ps::ps_memory_full_info(child)[["pss"]], error = function(e) 0)
  }
  total
}

process_rss <- function(root) ps::ps_memory_info(root)[["rss"]]

process_bytes <- if (whole_tree) tree_pss else process_rss

# Peak memory, in MB, of the fit, sampled while it runs.
peak_mb_sampled <- function(version, cell) {
  process <- processx::process$new(rscript, fit_args(version, cell), stdout = NULL, stderr = NULL)
  root <- process$as_ps_handle()
  samples <- numeric(0)
  while (process$is_alive()) {
    samples <- c(samples, tryCatch(process_bytes(root), error = function(e) NA_real_))
    Sys.sleep(interval)
  }
  if (process$get_exit_status() != 0) {
    stop("The ", version, " fit failed (exit status ", process$get_exit_status(), ").")
  }
  if (mean(is.na(samples)) > 0.1) {
    warning(sprintf("%.0f%% of the memory samples of the %s fit could not be read.", 100 * mean(is.na(samples)), version))
  }
  max(samples, na.rm = TRUE) / 2^20
}

peak_mb <- if (cgroups) peak_mb_cgroup else peak_mb_sampled

# Where workers cannot be measured, the size sweeps run with one thread.
single_process <- function(experiment) {
  if (length(experiment$threads) == 1) experiment$threads <- 1
  experiment
}

run_experiment <- function(name, experiment) {
  grid <- cells(experiment)
  measure_og <- whole_tree || length(experiment$threads) == 1
  rows <- lapply(seq_len(nrow(grid)), function(i) {
    cell <- grid[i, ]
    peak <- function(version) mean(converge(function() peak_mb(version, cell))$values)
    dry <- peak("dry")
    og <- if (measure_og) peak("og") - dry else NA_real_
    data.frame(experiment = name, cell, PPforest = og, ppforest2 = peak("nw") - dry, method = method)
  })
  do.call(rbind, rows)
}

report <- function(name, result, experiment) {
  keys <- c("n", "p", "q", "lambda", "pvars", "size", "threads")
  varying <- names(which(lengths(experiment[keys]) > 1))
  shown <- data.frame(result[varying], PPforest_MB = result$PPforest, ppforest2_MB = result$ppforest2)
  if (identical(varying, "threads")) {
    shown$PPforest_to_1_thread <- result$PPforest / result$PPforest[1]
    shown$ppforest2_to_1_thread <- result$ppforest2 / result$ppforest2[1]
  } else {
    shown$ratio <- result$PPforest / result$ppforest2
  }
  fixed <- experiment[setdiff(keys, varying)]
  cat(sprintf("\n%s (%s)\n", name, paste(names(fixed), unlist(fixed), sep = " = ", collapse = ", ")))
  print(shown, digits = 3, row.names = FALSE)
}

cat("Memory measured with", method, "\n")
if (!whole_tree) {
  cat("PPforest's workers cannot be measured here: size sweeps run with one thread, and thread sweeps measure ppforest2 only.\n")
}
results <- list()
chosen <- selected_experiments(commandArgs(trailingOnly = TRUE))
if (!whole_tree) chosen <- lapply(chosen, single_process)
for (name in names(chosen)) {
  results[[name]] <- run_experiment(name, chosen[[name]])
  report(name, results[[name]], chosen[[name]])
}

dir.create("benchmarks/results", showWarnings = FALSE)
utils::write.csv(do.call(rbind, results), "benchmarks/results/memory.csv", row.names = FALSE)
write_environment("memory")
