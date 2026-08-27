#!/usr/bin/env sh

# Re-vendor the committed nlohmann/json and pcg headers under `inst/include`.
#
# The pinned versions are read from the core repository's
# `core/Dependencies.cmake`, so the headers the R package compiles against
# cannot drift from the ones the core itself is built with. The headers are
# downloaded directly — the R package build uses no CMake.
#
# Every `#pragma (GCC|clang) diagnostic ignored` line is stripped, because that
# is the exact pattern `R CMD check`'s pragma check flags (tools:::.check_pragmas):
# the -Wfloat-equal suppression it treats as a WARNING, and the cosmetic ones
# (-Wdocumentation, -Wmismatched-tags, Hedley's -Wpedantic / -Wvariadic-macros)
# it reports as a NOTE. Only literal `#pragma ... ignored` lines match, so
# Hedley's `_Pragma(...)` macros and all push/pop blocks survive and the library
# still compiles.
#
# Usage:  tools/vendor-deps.sh <path-to-ppforest2-core>
# Or:     make vendor-deps CORE=../ppforest2-core

set -eu

CORE_REPO=${1:-}

if [ -z "${CORE_REPO}" ]; then
  echo "Usage: tools/vendor-deps.sh <path-to-ppforest2-core>" >&2
  exit 1
fi

DEPS="${CORE_REPO}/core/Dependencies.cmake"

if [ ! -f "${DEPS}" ]; then
  echo "ERROR: ${DEPS} not found. Point CORE at a ppforest2-core checkout." >&2
  exit 1
fi

JSON_URL=$(grep -o 'https://github.com/nlohmann/json/releases/download/[^[:space:]]*json\.tar\.xz' "${DEPS}" | head -1)
PCG_TAG=$(awk '/FetchContent_Declare/{block=""} {block=block" "$0} /pcg-cpp\.git/{found=1} found && /GIT_TAG/{print $2; exit}' "${DEPS}")

if [ -z "${JSON_URL}" ] || [ -z "${PCG_TAG}" ]; then
  echo "ERROR: could not read the json URL / pcg tag from ${DEPS}." >&2
  exit 1
fi

echo "* json: ${JSON_URL}"
echo "* pcg:  ${PCG_TAG}"

STAGE=$(mktemp -d)
trap 'rm -rf "${STAGE}"' EXIT

curl -fsSL "${JSON_URL}" -o "${STAGE}/json.tar.xz"
mkdir -p "${STAGE}/json"
tar -xJf "${STAGE}/json.tar.xz" -C "${STAGE}/json" --strip-components=1
git clone --quiet --depth 1 --branch "${PCG_TAG}" https://github.com/imneme/pcg-cpp.git "${STAGE}/pcg"

rm -rf inst/include/nlohmann
cp -R "${STAGE}/json/include/nlohmann" inst/include/
cp "${STAGE}/pcg/include/pcg_extras.hpp" \
   "${STAGE}/pcg/include/pcg_random.hpp" \
   "${STAGE}/pcg/include/pcg_uint128.hpp" inst/include/

find inst/include/nlohmann -name '*.hpp' -exec \
  perl -ni -e 'print unless m{^\s*#pragma (GCC|clang) diagnostic ignored}' {} +

sh tools/vendor-guard-json.sh inst/include/nlohmann/json.hpp

echo "* Done. Review 'git diff' and run 'make check-cran'."
