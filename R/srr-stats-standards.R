#' srr_stats
#'
#' All of the following standards initially have `@srrstatsTODO` tags.
#' These may be moved at any time to any other locations in your code.
#' Once addressed, please modify the tag from `@srrstatsTODO` to `@srrstats`,
#' or `@srrstatsNA`, ensuring that references to every one of the following
#' standards remain somewhere within your code.
#' (These comments may be deleted at any time.)
#'
#' @srrstatsVerbose TRUE
#'
#' @srrstatsTODO {G5.10} *Extended tests should included and run under a common framework with other tests but be switched on by flags such as as a `<MYPKG>_EXTENDED_TESTS="true"` environment variable.* - The extended tests can be then run automatically by GitHub Actions for example by adding the following to the `env` section of the workflow: 
#' @srrstatsTODO {G5.11} *Where extended tests require large data sets or other assets, these should be provided for downloading and fetched as part of the testing workflow.*
#' @srrstatsTODO {G5.11a} *When any downloads of additional data necessary for extended tests fail, the tests themselves should not fail, rather be skipped and implicitly succeed with an appropriate diagnostic message.*
#' @srrstatsTODO {G5.12} *Any conditions necessary to run extended tests such as platform requirements, memory, expected runtime, and artefacts produced that may need manual inspection, should be described in developer documentation such as a `CONTRIBUTING.md` or `tests/README.md` file.*
#' @srrstats {G1.1} The README section "Relation to other packages" states that
#'   the package improves on an existing R implementation, `PPforest`, of
#'   published algorithms, and how it differs from other oblique tree packages.
#' @srrstats {G1.2} The "Life cycle" section of `.github/CONTRIBUTING.md` is
#'   the life cycle statement.
#' @srrstats {G1.3} The "Terminology" section of the introduction vignette
#'   defines the statistical terms the package uses.
#' @srrstats {G1.6} `benchmarks/compare-ppforest.R` times forest training in
#'   ppforest2 and `PPforest` on simulated data, which is the basis of the
#'   performance claim in the README.
#' @noRd
NULL

#' NA_standards
#'
#' Any non-applicable standards can have their tags changed from `@srrstatsTODO`
#' to `@srrstatsNA`, and placed together in this block, along with explanations
#' for why each of these standards have been deemed not applicable.
#' (These comments may also be deleted at any time.)
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
#'   against. Correctness is tested against stored `PPforest` outputs instead
#'   (G5.4b).
#' @noRd
NULL
