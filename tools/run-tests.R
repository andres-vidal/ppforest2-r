# Run the test suite for `make test`.
#
# Test failures stop the run with a non-zero exit status, so CI fails on them.

devtools::load_all(".")
devtools::test(".", stop_on_failure = TRUE)
