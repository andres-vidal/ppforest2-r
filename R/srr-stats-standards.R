#' srr_stats
#'
#' Standards met in documentation outside `R/` and `tests/`. The others are
#' tagged next to the code or tests that meet them.
#'
#' @srrstatsVerbose TRUE
#'
#' @srrstats {G1.1} The README section "Relation to other packages" states that
#'   the package improves on an existing R implementation, `PPforest`, of
#'   published algorithms, and how it differs from other oblique tree packages.
#' @srrstats {G1.2} The README section "Life cycle" is the life cycle statement.
#' @srrstats {G1.3} The "Terminology" section of the introduction vignette
#'   defines the statistical terms the package uses.
#' @srrstats {G1.6} `benchmarks/compare-ppforest.R` times forest training in
#'   ppforest2 and `PPforest` on simulated data, which is the basis of the
#'   performance claim in the README.
#' @noRd
NULL

#' NA_standards
#'
#' @srrstatsNA {G1.5} No publication associated with the package makes
#'   performance claims. The comparison with `PPforest` is reproduced by
#'   `benchmarks/compare-ppforest.R` (G1.6).
#' @srrstatsNA {G2.4c} Nothing in the modelling path converts to character.
#' @srrstatsNA {G2.4e} Nothing converts a factor to another type.
#' @srrstatsNA {G2.10} Columns are only extracted from the internal numeric
#'   matrix, so extraction behaves the same for every input class.
#' @srrstatsNA {G2.14b, G2.14c} Missing values are an error (G2.14a). There is
#'   no option to ignore them, and imputation is left to the user before
#'   training.
#' @srrstatsNA {G3.1, G3.1a} The covariance is part of the LDA and PDA
#'   projection indices, not an estimator that users choose.
#' @srrstatsNA {G5.4c} There are no published numeric outputs to compare
#'   against. Correctness is tested against `PPforest` instead (G5.4b).
#' @srrstatsNA {G5.10, G5.11, G5.11a, G5.12} The package has no extended tests:
#'   every test runs in the regular suite on data bundled with the package.
#' @noRd
NULL
