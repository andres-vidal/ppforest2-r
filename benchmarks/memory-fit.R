# Trains one forest, for benchmarks/memory.R to measure the peak memory of
# this process. Arguments: version (og, nw, or dry for loading the packages
# and simulating the data without training), then n, p, q, lambda, pvars,
# size and threads.

source("benchmarks/common.R")

args <- commandArgs(trailingOnly = TRUE)
version <- args[1]
values <- as.numeric(args[-1])
names(values) <- c("n", "p", "q", "lambda", "pvars", "size", "threads")

set.seed(0)
data <- simulate(values[["n"]], values[["p"]], values[["q"]])

if (version != "dry") {
  model <- suppressWarnings(train(version, data, values[["lambda"]], values[["pvars"]], values[["size"]], values[["threads"]]))
}
