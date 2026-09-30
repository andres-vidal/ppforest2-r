# Check, in CI, that every package in DESCRIPTION's Suggests can be loaded.
#
# The tests guard optional packages with skip_if_not_installed(), which CRAN
# needs because it checks without Suggests. In CI every Suggests package is
# installed, so one that cannot be loaded means a broken environment, and the
# tests that use it would be skipped without failing anything. This prints the
# error from loading each such package and exits with a non-zero status. It does
# nothing unless CI is set, as GitHub Actions does.

if (nzchar(Sys.getenv("CI"))) {
  field <- read.dcf("DESCRIPTION", fields = "Suggests")[1, 1]
  pkgs <- trimws(sub("\\(.*\\)", "", strsplit(field, ",")[[1]]))
  pkgs <- pkgs[nzchar(pkgs)]

  errors <- vapply(pkgs, function(pkg) {
    tryCatch({
      loadNamespace(pkg)
      ""
    }, error = conditionMessage)
  }, character(1))
  unloadable <- errors[nzchar(errors)]

  for (pkg in names(unloadable)) {
    cat("::error::Suggested package ", pkg, " cannot be loaded: ", unloadable[[pkg]], "\n", sep = "")
  }
  if (length(unloadable) > 0) {
    quit(status = 1)
  }
}
