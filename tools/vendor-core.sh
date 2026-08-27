#!/usr/bin/env sh

# Vendor the C++ core into this repository.
#
# The package compiles the core directly into its shared object, so the core
# sources live here under `src/core` and are committed. This script refreshes
# them from a checkout of ppforest2-core at a given ref, and records that ref
# in `CORE_VERSION`.
#
# Usage:  tools/vendor-core.sh <path-to-ppforest2-core> <ref>
# Or:     make vendor-core CORE=../ppforest2-core REF=v0.1.4

set -eu

CORE_REPO=${1:-}
CORE_REF=${2:-}

if [ -z "${CORE_REPO}" ] || [ -z "${CORE_REF}" ]; then
  echo "Usage: tools/vendor-core.sh <path-to-ppforest2-core> <ref>" >&2
  exit 1
fi

if ! git -C "${CORE_REPO}" rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: ${CORE_REPO} is not a git repository." >&2
  exit 1
fi

if ! git -C "${CORE_REPO}" rev-parse --verify --quiet "${CORE_REF}^{commit}" >/dev/null; then
  echo "ERROR: ${CORE_REF} is not a commit in ${CORE_REPO}." >&2
  exit 1
fi

RESOLVED=$(git -C "${CORE_REPO}" rev-parse --short "${CORE_REF}")
STAGE=$(mktemp -d)
trap 'rm -rf "${STAGE}"' EXIT

echo "* Vendoring core from ${CORE_REPO} at ${CORE_REF} (${RESOLVED})"

git -C "${CORE_REPO}" archive "${CORE_REF}" core golden | tar -x -C "${STAGE}"

# The CLI, io, golden and test translation units are dropped: they need fmt,
# csv-parser and GoogleTest, none of which the R package builds against. The
# exclusions are mirrored in `configure`'s OBJECTS list.
rm -rf src/core
mkdir -p src/core
cp -R "${STAGE}/core/include" src/core/include
cp -R "${STAGE}/core/src" src/core/src
rm -rf src/core/src/cli src/core/src/io src/core/src/golden
find src/core -name '*.test.cpp' -delete
rm -f src/core/src/test.cpp
find src/core -name 'CMakeLists.txt' -delete

# Golden files are the cross-platform reproducibility contract, verified by
# test-golden.R and test-json.R against the same files the core tests use.
rm -rf inst/golden
cp -R "${STAGE}/golden" inst/golden

echo "${CORE_REF}" > CORE_VERSION

echo "* Vendored $(find src/core -name '*.cpp' | wc -l | tr -d ' ') core sources and $(find inst/golden -type f | wc -l | tr -d ' ') golden files."
echo "* CORE_VERSION is now ${CORE_REF}."
echo "* Review 'git diff' and run 'make check-cran'."
