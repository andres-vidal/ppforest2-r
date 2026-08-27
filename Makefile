MAKEFLAGS += --no-print-directory

PACKAGE = ppforest2
VERSION := $(shell sed -n 's/^Version: //p' DESCRIPTION)
TARBALL = ${PACKAGE}_${VERSION}.tar.gz
CRAN_MIRROR = https://cran.rstudio.com/

# Where to find a ppforest2-core checkout for the vendoring targets, and which
# ref to vendor. The currently vendored ref is recorded in CORE_VERSION.
CORE ?= ../ppforest2-core
REF ?=

install-deps:
	@Rscript -e "if (!requireNamespace('pak', quietly = TRUE)) install.packages('pak', repos = '${CRAN_MIRROR}')"
	@Rscript -e "pak::local_install_deps('.')"

# Note: src/core, inst/golden, inst/include/nlohmann and inst/include/pcg_*.hpp
# are vendored (committed) and must NOT be removed here.
clean:
	@find src -name '*.o' -delete
	@rm -rf \
		src/*.so \
		src/*.dll \
		src/*.rds \
		src/Makevars \
		src/Makevars.win \
		src/VERSION \
		inst/lib \
		${PACKAGE}.Rcheck

document:
	@Rscript -e "devtools::document('.')"

build: clean
	@Rscript -e "Rcpp::compileAttributes('.')"
	@R CMD build .

test:
	@Rscript -e "Rcpp::compileAttributes('.')"
	@Rscript -e "devtools::load_all('.'); devtools::test('.')"
	@make clean

# `R CMD check` exits 0 on WARNINGs (only ERRORs are non-zero), so a WARNING
# would silently pass CI. In CI ($CI is set by GitHub Actions) we additionally
# fail on any check WARNING. The "checking top-level files" WARNING is excluded
# because it fires wherever `checkbashisms` is not installed (macOS/Windows
# runners) and is a tooling-absence artifact, not a package defect.
define fail_on_warning
	@if [ -n "$$CI" ]; then \
		warns=$$(grep -E '^\* .*\.\.\. WARNING' ${PACKAGE}.Rcheck/00check.log | grep -v 'checking top-level files' || true); \
		if [ -n "$$warns" ]; then \
			echo "::error::R CMD check reported WARNING(s):"; \
			grep -E '^Status:|WARNING' ${PACKAGE}.Rcheck/00check.log; \
			exit 1; \
		fi; \
	fi
endef

check: build
	@R CMD check ${TARBALL} || exit 1
	$(fail_on_warning)

check-cran: build
	@R CMD check ${TARBALL} --as-cran || exit 1
	$(fail_on_warning)

install: build
	@R CMD INSTALL ${TARBALL}

# Refresh the vendored C++ core and golden files from a ppforest2-core checkout,
# and record the ref in CORE_VERSION.
docs:
	@Rscript -e "Rcpp::compileAttributes('.')"
	@Rscript -e "pkgdown::build_site('.', preview = FALSE)"

vendor-core:
	@if [ -z "${REF}" ]; then \
		echo "Usage: make vendor-core CORE=../ppforest2-core REF=v0.1.4"; \
		exit 1; \
	fi
	@sh tools/vendor-core.sh ${CORE} ${REF}

# Refresh the vendored nlohmann/json and pcg headers, at the versions pinned in
# the core repository's core/Dependencies.cmake.
vendor-deps:
	@sh tools/vendor-deps.sh ${CORE}

.PHONY: install-deps clean document build test check check-cran install vendor-core vendor-deps docs
