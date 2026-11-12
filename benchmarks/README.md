# Benchmarks

Scripts that compare the training time and memory of ppforest2 with those of
`PPforest`, the previous R implementation of projection pursuit forests. They
reproduce, at a smaller scale, the experiments behind the performance results
of Vidal (2026), *ppforest2: una reimplementación eficiente de los bosques de
proyección* (<https://hdl.handle.net/20.500.12008/56830>). The results are
presented in the
[performance article](https://andres-vidal.github.io/ppforest2-r/articles/performance.html).

| File | Purpose |
|---|---|
| `common.R` | Data generator, how each package trains a forest, the experiments, and the convergence rule |
| `speed.R` | Training time of both packages, by experiment |
| `memory.R` | Peak memory of both packages, by experiment |
| `memory-fit.R` | Trains one forest in its own process, for `memory.R` to measure |
| `scaling.R` | Growth of ppforest2's training time with `n` and `p` (RE5.0) |
| `results/` | The results the article shows, and the machine and package versions they were computed with |

## Experiments

Each experiment varies one parameter and fixes the rest, and keeps the name it
has in the thesis. The grids start where the two implementations begin to
differ and stop at sizes that run on a laptop, and forests have fewer trees
than in the thesis, so the shape of each result is reproduced but not its
magnitudes.

| Experiment | Varies | Fixed |
|---|---|---|
| `n` | observations: 1024 to 8192 | p = 4, q = 2, all cores |
| `p` | variables: 64 to 512 | n = 32, q = 2, all cores |
| `p_v05` | variables: 64 to 512, half of them per split | n = 32, q = 2, all cores |
| `q` | groups: 16 to 128 | n = 2048, p = 4, all cores |
| `l` | lambda: 0 to 1 | n = 512, p = 8, q = 8, all cores |
| `v` | variables per split: 25% to 100% | n = 512, p = 32, q = 4, all cores |
| `f` | trees: 100 to 1000 | n = 128, p = 8, q = 4, all cores |
| `t_n`, `t_p`, `t_q` | threads: 1 to all cores | one of n = 8192, p = 128 or q = 16 large, 200 trees |
| `s_n`, `s_p`, `s_q` | observations, variables or groups | one thread |

Forests have 100 trees, lambda = 0.5 and every variable per split unless the
experiment varies them. The data is simulated with the thesis's generator:
`q` groups of `ceiling(n / q)` normal observations in `p` variables, each
group with a random mean and covariance, from seed 0.

## Requirements

- ppforest2, and `MASS` for the data generator.
- `PPforest` 0.2.1, which fixes how `PPforest` 0.2.0 counts votes and labels
  groups. Until it is released, install it from the pull request's commit:

  ```r
  remotes::install_github("andres-vidal/PPforest@88a52f35b298eb93e3eb3883e81f3f0218278e57")
  ```

  `PPforest` 0.2.0 fails with 20 or more groups, so the `q` experiments do
  not run on it.
- `processx` and `ps`, for `memory.R` where it samples the processes.

## Running

From the repository root:

```sh
Rscript benchmarks/speed.R            # every experiment
Rscript benchmarks/speed.R n q t_n    # some of them
Rscript benchmarks/memory.R
```

Each script prints a table per experiment and writes its results to
`results/speed.csv` or `results/memory.csv`, and the machine and package
versions to `results/speed-environment.txt` or
`results/memory-environment.txt`. On a 10-core laptop each script takes about
half an hour.

## Measurement

**Convergence.** Each measurement is repeated until it is stable, with the
rule of the ppforest2-core benchmark runner: after at least 5 runs, the
coefficient of variation of all the runs must stay below 5% for 3 consecutive
runs. A cell stops unconverged after 30 runs or 120 seconds, and the results
record how many runs each cell took and whether it converged.

**Time** is the elapsed time of `PPforest::PPforest()` or `ppforest2::pprf()`,
measured with `system.time()`. Its resolution is about a millisecond, so the
fastest ppforest2 fits, which take a few milliseconds, often do not converge,
and the largest ratios are approximate.

**Memory** is the peak the training adds: each fit runs in its own R process,
and the peak of a process that only loads the packages and simulates the same
data is subtracted. ppforest2 trains its trees in threads of one process,
while `PPforest` forks worker processes that share the parent's memory until
they write to it, so every process must be counted, and shared pages only
once:

- On Linux with systemd and cgroup v2, each fit runs in its own transient
  cgroup, and the kernel's `memory.peak` for the cgroup is read. This is the
  method of the thesis.
- On other Linux systems, the processes are sampled every 20 ms, and their
  proportional set sizes, which split shared pages among the processes using
  them, are added up.
- On macOS, shared pages cannot be told apart from a worker's own without
  root, so only single processes are measured: the size experiments run with
  one thread for both packages, and the thread experiments measure ppforest2
  alone. The resident set size is sampled every 20 ms.

The method is recorded in each row of `results/memory.csv`. Sampled peaks can
miss a spike shorter than the sampling interval.
