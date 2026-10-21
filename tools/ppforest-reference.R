# Writes tests/testthat/fixtures/ppforest-reference.txt, the reference that
# test-correctness.R compares single trees against. For each dataset and value
# of lambda it stores the root projection of the tree that
# PPforest::PPtree_split() trains and the class it predicts for every row,
# together with the PPforest version that produced them.
#
# Run from the package root, with PPforest installed:
#
#   Rscript tools/ppforest-reference.R

datasets <- c("iris", "crab", "wine", "glass", "fishcatch")
lambdas <- c(0, 0.5)

# Each dataset as a data frame whose response column is a factor named `Type`.
load_dataset <- function(name) {
  if (name == "iris") {
    data <- stats::setNames(datasets::iris, c(names(datasets::iris)[1:4], "Type"))
  } else {
    env <- new.env()
    load(file.path("data", paste0(name, ".rda")), envir = env)
    data <- env[[name]]
  }
  data$Type <- factor(data$Type)
  data
}

# Class index predicted for each row of `x` by a tree from
# `PPforest::PPtree_split()`, using its first cutoff rule. In `Tree.Struct`, an
# internal node has its children in `L.node.ID` and `R.F.node.ID` and its
# projection in row `Coef.ID`; a leaf has `L.node.ID` 0 and its class in
# `R.F.node.ID`.
classify_pptree <- function(tree, x) {
  structure <- tree$Tree.Struct
  apply(x, 1, function(row) {
    node <- 1
    while (structure[node, "L.node.ID"] != 0) {
      coef <- structure[node, "Coef.ID"]
      projected <- sum(row * tree$projbest.node[coef, ])
      node <- if (projected < tree$splitCutoff.node[coef, 1]) {
        structure[node, "L.node.ID"]
      } else {
        structure[node, "R.F.node.ID"]
      }
    }
    structure[node, "R.F.node.ID"]
  })
}

trees <- list()

for (name in datasets) {
  data <- load_dataset(name)
  x <- as.matrix(data[, setdiff(names(data), "Type")])

  for (lambda in lambdas) {
    method <- if (lambda == 0) "LDA" else "PDA"
    tree <- PPforest::PPtree_split("Type ~ .", data, PPmethod = method, size.p = 1, lambda = lambda)

    trees[[length(trees) + 1L]] <- list(
      dataset = name,
      lambda = lambda,
      projector = unname(tree$projbest.node[1, ]),
      predictions = levels(data$Type)[classify_pptree(tree, x)]
    )
  }
}

reference <- list(
  ppforest_version = as.character(utils::packageVersion("PPforest")),
  trees = trees
)

path <- file.path("tests", "testthat", "fixtures", "ppforest-reference.txt")
dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
dput(reference, path, control = c("keepNA", "keepInteger", "niceNames", "digits17"))
cat("Wrote", path, "from PPforest", reference$ppforest_version, "\n")
