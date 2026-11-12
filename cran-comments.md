## Resubmission

This is a resubmission. The previous 0.1.4 tarball accidentally included the
package's `.git` directory, which the incoming check flagged as a hidden
directory. It is now excluded via `.Rbuildignore`, and the tarball contains no
hidden files.

## Update

This is an update (0.1.4). Its main purpose is to fix incorrect results.

* For classification forests trained on data whose rows are not sorted by the
  levels of the response, `oob_error()`, `oob_predictions()`,
  `permuted_importance()` and `weighted_importance()` used the wrong
  out-of-bag observations, so the reported out-of-bag error was too low.
* For regression models, `fitted()` and `residuals()` did not line up with the
  training rows.
* `predict()` silently dropped rows with missing values, and returned
  predictions for `new_data` with a different number of columns from the
  training data. It now errors in both cases.

The update also vendors version 0.1.4 of the C++ core, validates inputs more
strictly, and lets `predict()` take new data without the response column. See
NEWS.md.

## Test environments

* local macOS (R 4.6.1), R CMD check --as-cran
* GitHub Actions: Ubuntu (R release, oldrel-1 and devel), macOS (with and
  without OpenMP) and Windows (R release), R CMD check --as-cran

## Notes for the reviewer

* The package bundles a small amount of third-party C++ header code
  (nlohmann/json and the PCG random number generator) under `inst/include/`,
  used by the C++ core. The vendored nlohmann/json headers are modified only in
  two non-functional ways: their `#pragma GCC/clang diagnostic ignored` lines
  are removed (so the library suppresses no compiler diagnostics), and
  `json.hpp` is bracketed with a `_Pragma` guard that silences the libc++
  `char_traits<unsigned char>` deprecation (the fix in 0.1.2). The headers are
  otherwise upstream. Eigen is obtained from RcppEigen via LinkingTo. No code is
  downloaded at build or install time; the package builds entirely from the
  sources in the tarball and does not require CMake.

* OpenMP is used for optional multi-threaded forest training and is guarded by
  `#ifdef _OPENMP`; the package builds and runs correctly without it.

* All random number generation in the C++ core is seeded explicitly from R via
  `set.seed()`, so results are reproducible across platforms.

* The author name "da Silva" (Natalia da Silva) in the Description may be flagged
  by the incoming spell check as a possibly misspelled "da"; it is spelled
  correctly.
