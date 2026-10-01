# Contributing to ppforest2

Thanks for your interest in contributing. This repository is the R package.
The C++ engine it compiles lives in
[ppforest2-core](https://github.com/andres-vidal/ppforest2-core) and is
vendored here under `src/core/`.

## Reporting issues

- Search the [issue tracker](https://github.com/andres-vidal/ppforest2-r/issues)
  first to avoid duplicates.
- For bugs, please include a minimal reproducible example (a
  [reprex](https://reprex.tidyverse.org/)) and the output of
  `sessionInfo()` or `sessioninfo::session_info()`.
- For a question about usage rather than a bug, feel free to open an issue
  labelled "question".

## Pull requests

- Open an issue describing the change before starting substantial work, so we
  can agree on the approach.
- Fork the repository and create a branch off `main`.
- Changes to the C++ core go to
  [ppforest2-core](https://github.com/andres-vidal/ppforest2-core), not to
  `src/core/` or `inst/golden/` here. Both are copies refreshed with
  `make vendor-core`.
- Follow the existing code style. R code follows the tidyverse style guide;
  C++ code is formatted with `clang-format` (`make format`).
- Add tests for any behaviour you change or add. Tests use
  [testthat](https://testthat.r-lib.org/) under `tests/testthat/`.
- Run the test suite with `make test` and the full package check with
  `make check` before submitting. Add an entry to `NEWS.md` in the same commit
  as a user-facing change.
- Keep documentation in sync: R docs are generated from `roxygen2` blocks
  (`make document`); never hand-edit `NAMESPACE` or files under `man/`.

## Code of Conduct

By participating in this project you agree to abide by its
[Code of Conduct](CODE_OF_CONDUCT.md).
