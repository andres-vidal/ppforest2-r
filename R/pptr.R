#' @useDynLib ppforest2
#' @importFrom Rcpp evalCpp
#' @importFrom stats model.frame model.matrix model.response formula predict sd terms update fitted residuals nobs
NULL

#' Trains a Projection-Pursuit oblique decision tree.
#'
#' This function trains a Projection-Pursuit oblique decision tree using either a formula and data frame interface or a matrix-based interface. When using the formula interface, specify the model formula and the data frame containing the variables. For the matrix-based interface, provide matrices for the features and labels directly.
#' If \code{lambda = 0}, the model is trained using Linear Discriminant Analysis (LDA). If \code{lambda > 0}, the model is trained using Penalized Discriminant Analysis (PDA).
#'
#' Mode is taken from the \code{mode} argument when explicit, and otherwise auto-detected from `y` (factor/character → classification, numeric → regression). Pass \code{mode = "classification"} to force classification on integer labels (e.g. binary 0/1), or \code{mode = "regression"} to assert intent on numeric responses.
#'
#' @param formula A formula of the form \code{y ~ x1 + x2 + ...}, where \code{y} is a vector of labels and \code{x1}, \code{x2}, ... are the features.
#' @param data A data frame containing the variables in the formula.
#' @param x A numeric matrix or data frame of features, one row per observation. It must have at least one row and one column, and no missing or infinite values.
#' @param y The response, one value per row of \code{x}: a factor or character vector of labels for classification, or a numeric vector for regression. It must have no missing values. For classification, a character vector is converted with \code{factor()}; the groups are the factor's levels, in level order, and are treated as unordered. There must be at least as many observations as groups.
#' @param mode Training mode: either \code{"classification"} or \code{"regression"} (case-sensitive). When \code{NULL} (default), mode is auto-detected from \code{y}'s type — factor or character vectors trigger classification, numeric vectors trigger regression. Setting it explicitly is useful for the binary-integer-labels case (\code{mode = "classification"} with integer 0/1 labels) and for failing fast on a type mismatch (\code{mode = "regression"} with a factor \code{y} errors immediately).
#' @param lambda A regularization parameter (default: 0.5). If \code{lambda = 0}, the model is trained using Linear Discriminant Analysis (LDA). If \code{lambda > 0}, the model is trained using Penalized Discriminant Analysis (PDA). The default uses PDA because pure LDA (\code{lambda = 0}) is ill-conditioned when there are more variables than effective observations (see the "Known limitations" section of the README). Cannot be used together with \code{pp}.
#' @param seed An optional integer seed for reproducibility. If \code{NULL} (default), a seed is drawn from R's RNG, so \code{set.seed()} controls reproducibility. If an integer is provided, that value is used directly.
#' @param pp A projection pursuit strategy object created by \code{\link{pp_pda}}. Cannot be used together with \code{lambda}.
#' @param cutpoint A split cutpoint strategy object created by \code{\link{cutpoint_mean_of_means}} (default).
#' @param stop A stopping rule object. Default depends on mode:
#'   \code{\link{stop_pure_node}()} for classification, and
#'   \code{stop_any(stop_min_size(5), stop_min_variance(0.01))} for regression.
#' @param binarize A binarization strategy object. Default depends on mode:
#'   \code{\link{binarize_largest_gap}()} for classification, and
#'   \code{\link{binarize_disabled}()} for regression (regression's default
#'   grouping always yields a 2-group partition, so no binarization is needed).
#' @param grouping A grouping strategy object. Default depends on mode:
#'   \code{\link{grouping_by_label}()} for classification, and
#'   \code{\link{grouping_by_cutpoint}()} for regression.
#' @param leaf A leaf strategy object. Default depends on mode:
#'   \code{\link{leaf_majority_vote}()} for classification, and
#'   \code{\link{leaf_mean_response}()} for regression.
#' @section Input data:
#' With the formula interface, the feature matrix is built with
#' \code{model.matrix()} from the formula without an intercept: numeric
#' columns are used as they are, and each factor predictor becomes indicator
#' columns, one per level. The response is taken with \code{model.response()}.
#' With the matrix interface, \code{x} is converted with \code{as.matrix()}.
#'
#' Features must be numeric. Factor predictors are accepted only through the
#' formula interface; character and list columns are an error, and so are
#' missing or infinite values in the features or the response. Rows with
#' missing values are not dropped: remove or impute them before training.
#'
#' A classification response that is not a factor is converted with
#' \code{factor()}. To choose the groups and their order, pass \code{y} as a
#' factor with those levels; to treat integer labels as groups, use
#' \code{mode = "classification"}.
#'
#' The method makes no distributional assumptions. Each split looks for a
#' linear combination of the features that separates the groups, so groups
#' that differ only in non-linear ways need more splits. Results do not depend
#' on the units of the features: rescaling or shifting a feature leaves the
#' splits and predictions unchanged. Perfectly collinear features, or more
#' features than observations at a node, make the LDA index
#' (\code{lambda = 0}) singular; the node then cannot be split, it becomes a
#' degenerate leaf, and a warning is issued. The PDA index (\code{lambda > 0})
#' is not affected. A warning is also issued for features that are perfectly
#' collinear with each other or with a regression response.
#'
#' The row and column names of the training data are kept in the model's
#' \code{x}, and the column names in its variable importance. Predictions are
#' returned in the order of the rows of \code{new_data}, without row names.
#'
#' @return A \code{pptr} model: a list with S3 class
#'   \code{c("pptr_classification", "pptr", "ppmodel")} or
#'   \code{c("pptr_regression", "pptr", "ppmodel")}, depending on the mode.
#'   Its elements include \code{root} (the fitted tree); \code{x} and
#'   \code{y} (the training features and response, in the order given, with
#'   \code{y} holding group indices for classification); \code{groups} (the
#'   class labels); \code{mode}; \code{formula} (\code{NULL} for the matrix
#'   interface); \code{training_spec} (the strategies used); \code{seed};
#'   \code{degenerate} (\code{TRUE} when some node could not be split, see
#'   Input data); and \code{vi} (variable importance). Where an accessor
#'   exists, such as \code{fitted()}, \code{residuals()}, \code{nobs()} or
#'   \code{formula()}, prefer it to the element.
#' @seealso \code{\link{predict.pptr_classification}}, \code{\link{predict.pptr_regression}}, \code{\link{formula.ppmodel}}, \code{\link{print.pptr}}, \code{\link{save_json}}, \code{\link{load_json}}, \code{\link{pp_tree}} for parsnip integration
#' @references
#' Lee, Y. D., Cook, D., Park, J. and Lee, E.-K. (2013). PPtree: Projection pursuit classification tree. \emph{Electronic Journal of Statistics}, 7. \doi{10.1214/13-EJS810}
#'
#' @srrstats {G1.0} The primary references for the method are listed under
#'   References and in `DESCRIPTION`.
#' @srrstats {G1.4} Every exported function is documented with roxygen2.
#' @srrstats {RE1.0} Models can be specified with a formula.
#' @srrstats {RE1.1, RE1.2, RE1.3a, RE1.4, RE2.0} The "Input data" section
#'   documents how the formula becomes a feature matrix, the accepted and
#'   rejected predictor types, the transformations applied and how to avoid
#'   them, the assumptions and the effect of violating them, and that row names
#'   are not carried into predictions.
#' @srrstats {RE1.3} The row and column names of the training data are kept in
#'   `model$x`, and the column names in the variable importance vectors.
#' @srrstats {RE3.0, RE3.1} Nodes that projection pursuit cannot split, the
#'   analogue of a failure to converge, produce a warning that can be
#'   suppressed, and the model records them in `degenerate`.
#' @srrstats {RE3.2, RE3.3} The stopping rules, which decide when a node stops
#'   splitting, have documented defaults and are set with the `stop` argument;
#'   `max_retries` in `pprf()` sets how often a degenerate tree is retrained.
#' @srrstats {RE4.0, RE4.7, RE4.8, RE4.13} The model object has its own S3
#'   classes and holds the training features and response, their metadata (the
#'   group labels and feature names) and the degenerate-node indicator.
#' @srrstats {G2.4a} `seed` must be integer-valued and is converted with
#'   `as.integer()` before reaching the C++ core.
#' @examples
#'
#' # Example 1: formula interface with the `iris` dataset
#' pptr(Species ~ ., data = iris)
#'
#' # Example 2: formula interface with the `iris` dataset with regularization
#' pptr(Species ~ ., data = iris, lambda = 0.5)
#'
#' # Example 3: matrix interface with the `iris` dataset
#' pptr(x = iris[, 1:4], y = iris[, 5])
#'
#' @export
pptr <- function(
    formula = NULL,
    data = NULL,
    x = NULL,
    y = NULL,
    mode = NULL,
    lambda = 0.5,
    seed = NULL,
    pp = NULL,
    cutpoint = NULL,
    stop = NULL,
    binarize = NULL,
    grouping = NULL,
    leaf = NULL) {
  # See the matching comment in `pprf()` — capture the call up front so
  # `update()` can rebuild and re-evaluate it.
  cl <- match.call()

  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1 || seed != as.integer(seed)))
    stop("`seed` must be a single integer or NULL.")

  args <- resolve_model_data(formula, data, x, y, mode = mode)
  mode <- args$mode

  strategies <- resolve_strategies(
    pp = pp, lambda = lambda, lambda_missing = missing(lambda),
    cutpoint = cutpoint, stop = stop, binarize = binarize, grouping = grouping,
    leaf = leaf)

  x <- args$x
  y <- args$y
  groups <- args$groups
  formula <- args$formula

  if (is.null(seed)) {
    seed <- sample.int(.Machine$integer.max, 1L)
  }

  training_spec <- list(
    pp = strategies$pp,
    vars = strategies$vars,
    cutpoint = strategies$cutpoint,
    stop = strategies$stop,
    binarize = strategies$binarize,
    grouping = strategies$grouping,
    leaf = strategies$leaf,
    mode = mode,
    size = 0L,
    seed = as.integer(seed),
    threads = 0L,
    max_retries = 3L)

  # `ppforest2_train` is mode-aware on the C++ side: it dispatches on
  # `training_spec$mode` and applies the appropriate index decode + sort.
  model <- ppforest2_train(training_spec, args$x, args$y)

  if (isTRUE(model$degenerate)) {
    warning("Some splits could not separate groups (degenerate nodes). ",
            "This can be caused by ill-conditioned variables in the input data. ",
            "Degenerate nodes predict the group with the most observations.",
            call. = FALSE)
  }

  model$call    <- cl
  model$seed    <- seed
  model$groups  <- groups
  model$formula <- formula
  model$mode    <- mode
  model$x       <- x
  model$y       <- y

  scale <- feature_scale(x)

  model$vi <- list(
    scale       = scale,
    projections = stats::setNames(ppforest2_vi_projections_tree(model, ncol(x), scale), colnames(x))
  )

  model$.cache <- .new_cache()

  # Class is set by the Rcpp wrap layer (see `make_model_class` in
  # bindings/R/inst/include/ppforest2.h), which derives it from
  # `tree.training_spec->mode`. Don't reassign here — that would let the
  # R-side guess drift away from the C++ truth.

  model
}


# ---------------------------------------------------------------------------
# Prediction: split per mode.
# ---------------------------------------------------------------------------

#' Predicts labels or per-group one-hot proportions from a pptr model (classification mode).
#'
#' @param object A \code{pptr_classification} model.
#' @param new_data A data frame or matrix of new observations. If \code{NULL}, the first positional argument in \code{...} is used for backward compatibility.
#' @param type Case-sensitive. \code{"class"} (default) returns a factor of predicted labels; \code{"prob"} returns a data frame with 1.0 for the predicted group and 0.0 elsewhere.
#' @param ... Backward-compat positional `new_data`.
#' @return A factor or data frame.
#' @seealso \code{\link{pptr}}, \code{\link{predict.pptr_regression}}
#' @export
predict.pptr_classification <- function(object, new_data = NULL, type = NULL, ...) {
  x <- process_predict_arguments(object, new_data, ...)
  if (is.null(type)) type <- "class"
  check_prediction_type(type)

  if (type == "prob") {
    probs <- ppforest2_predict_tree_prob(object, x)
    df <- as.data.frame(probs)
    colnames(df) <- object$groups
    return(df)
  }

  if (type != "class") {
    stop("`type = \"", type, "\"` is not supported for classification trees. ",
         "Use \"class\" (default) or \"prob\".", call. = FALSE)
  }

  y <- ppforest2_predict_tree(object, x)
  factor(object$groups[y], levels = object$groups)
}

#' Predicts numeric responses from a pptr model (regression mode).
#'
#' @param object A \code{pptr_regression} model.
#' @param new_data A data frame or matrix of new observations.
#' @param type Must be \code{"response"} (default; case-sensitive).
#' @param ... Backward-compat positional `new_data`.
#' @return A numeric vector.
#' @seealso \code{\link{pptr}}, \code{\link{predict.pptr_classification}}
#' @export
predict.pptr_regression <- function(object, new_data = NULL, type = NULL, ...) {
  x <- process_predict_arguments(object, new_data, ...)
  if (is.null(type)) type <- "response"
  check_prediction_type(type)

  if (type %in% c("class", "prob")) {
    stop("`type = \"", type, "\"` is not available for regression models. ",
         "Use `type = \"response\"`.", call. = FALSE)
  }

  if (type != "response") {
    stop("`type = \"", type, "\"` is not recognised. Use \"response\".", call. = FALSE)
  }

  as.numeric(ppforest2_predict_tree(object, x))
}


# ---------------------------------------------------------------------------
# print.pptr -- tree structure. Leaf label formatting is mode-specific via
# the `print_node` generic dispatched on the model's class.
# ---------------------------------------------------------------------------

#' Prints the structure of a pptr tree.
#' @param x A \code{pptr} model.
#' @param ... Unused.
#' @return Invisibly returns the input \code{pptr} model \code{x} (unchanged).
#'   Called for its side effect of printing the tree structure -- the oblique
#'   split rules and leaf predictions -- to the console.
#' @srrstats {RE4.17} `print()` shows the training specification and the tree.
#' @export
print.pptr <- function(x, ...) {
  cat("\n")
  if (!is.null(x$call)) {
    cat("Call: ", paste(deparse(x$call, width.cutoff = 80L), collapse = "\n      "), "\n\n", sep = "")
  }
  cat("Projection-Pursuit Oblique Decision Tree:\n")
  print_node(x, x$root)
  cat("\n")
  invisible(x)
}

#' Print a tree node and its subtree.
#'
#' Dispatches on the model's class so that leaf values are formatted per mode.
#' @noRd
print_node <- function(model, node, depth = 0) UseMethod("print_node")

#' @export
print_node.pptr_classification <- function(model, node, depth = 0) {
  .print_node_impl(model, node, depth, function(value) model$groups[value])
}

#' @export
print_node.pptr_regression <- function(model, node, depth = 0) {
  .print_node_impl(model, node, depth, function(value) format(as.numeric(value), digits = 4))
}

#' Print a tree node recursively.
#'
#' `format_leaf` turns a raw leaf value into the string printed for it.
#' @noRd
.print_node_impl <- function(model, node, depth, format_leaf) {
  indent <- paste(rep(" ", depth), collapse = "")

  if (!is.null(node$value)) {
    cat(indent, "Predict:", format_leaf(node$value), "\n")
    return(invisible(NULL))
  }

  projection_str <- paste(
    "[", paste(round(node$projector, 2), collapse = " "), "] * x",
    collapse = ""
  )

  cat(indent, "If (", projection_str, ") < ", node$cutpoint, ":\n", sep = "")

  if (!is.null(node$lower)) {
    print_node(model, node$lower, depth + 1)
  }

  cat(indent, "Else:\n", sep = "")

  if (!is.null(node$upper)) {
    print_node(model, node$upper, depth + 1)
  }
}


# ---------------------------------------------------------------------------
# summary -- layered via NextMethod:
#   summary.pptr_classification / summary.pptr_regression
#     -> summary.pptr (tree-level header + VI table)
#       -> summary.ppmodel (data summary block)
# ---------------------------------------------------------------------------

#' @export
summary.pptr <- function(object, ...) {
  model <- object
  if (is.null(model$x)) {
    cat("\n(Empty pptr model -- no training data available.)\n")
    return(invisible(model))
  }

  cat("\n")
  cat(if (identical(model$mode, "regression")) {
    "Projection-Pursuit Oblique Regression Tree\n"
  } else {
    "Projection-Pursuit Oblique Decision Tree\n"
  })
  cat("\n")
  print_training_spec(model$training_spec)

  NextMethod()  # summary.ppmodel

  invisible(model)
}

#' @export
summary.pptr_classification <- function(object, ...) {
  NextMethod()
  model <- object

  print_confusion_matrix(ppforest2_predict_tree(model, model$x), model)
  cat("\n")

  .print_vi_table(model, include_oob_importances = FALSE)
  invisible(model)
}

#' @export
summary.pptr_regression <- function(object, ...) {
  NextMethod()
  model <- object

  preds <- ppforest2_predict_tree(model, model$x)
  y <- model$y
  mse <- mean((preds - y)^2)
  mae <- mean(abs(preds - y))
  ss_tot <- sum((y - mean(y))^2)
  r2 <- if (ss_tot > 0) 1 - sum((preds - y)^2) / ss_tot else 0
  cat("Training Metrics:\n")
  cat("  MSE:", format(mse, nsmall = 6), "\n")
  cat("  MAE:", format(mae, nsmall = 6), "\n")
  cat("  R\u00b2: ", format(r2, nsmall = 6), "\n\n")

  .print_vi_table(model, include_oob_importances = FALSE)
  invisible(model)
}
