## Update

This is an update (0.1.3). Its main purpose is to build with the upcoming
RcppEigen release based on Eigen 5.

The vendored C++ core used `Eigen::all`, which Eigen 5 no longer accepts as an
index. It now uses `Eigen::indexing::all`, which is available since Eigen 3.4.0.
The change was contributed by Dirk Eddelbuettel, the RcppEigen maintainer. The
package was checked against the current CRAN RcppEigen (0.3.4.0.2, Eigen 3.4.0)
and against the RcppEigen 0.4.9.9.2 release candidate (Eigen 5.0.1).

The update also fixes an internal error in `pptr()` and `pprf()` for some
orderings of the response's classes, clamps the OpenMP thread count to at
least 1, and includes minor `summary()` and plot changes. See NEWS.md.

## Test environments

* local macOS (R release), R CMD check --as-cran, with CRAN RcppEigen 0.3.4.0.2
  and with the RcppEigen 0.4.9.9.2 release candidate
* GitHub Actions: Ubuntu, macOS, and Windows (R release), R CMD check --as-cran
* win-builder: R-devel and R-release
* R-devel (Linux, r-hub ubuntu-next container), R CMD check --as-cran
* AddressSanitizer + UndefinedBehaviorSanitizer, clang and gcc (r-hub containers)
* valgrind (r-hub container)

## R CMD check results

0 errors | 0 warnings | 0 notes

(If the incoming check flags "da" as possibly misspelled in the Description,
that is part of the author name "da Silva" (Natalia da Silva) and is spelled
correctly.)

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
