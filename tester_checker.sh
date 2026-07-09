#!/bin/bash
# ================================================================
#  The Matrix — Welcome to the Real World of Data Engineering
#  Automated Tester v1.0
#  Run from the project root (the dir containing ex0/, ex1/, ex2/).
#  Usage: bash tester_matrix.sh
# ================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

PASS=0; FAIL=0

# ── helpers ─────────────────────────────────────────────────────

banner() {
    echo -e "\n${CYAN}${BOLD}── $1 ─────────────────────────────────────────────${NC}"
}

ok() {
    echo -e "  ${GREEN}[OK]${NC} $1"
    PASS=$((PASS + 1))
}

ko() {
    echo -e "  ${RED}[KO]${NC} $1"
    [ -n "$2" ] && echo -e "       ${DIM}↳ $2${NC}"
    FAIL=$((FAIL + 1))
}

info() {
    echo -e "  ${YELLOW}[··]${NC} ${DIM}$1${NC}"
}

chk_file() { [ -f "$1" ] && ok "file: $1"  || ko "file: $1"  "NOT FOUND"; }
chk_dir()  { [ -d "$1" ] && ok "dir:  $1/" || ko "dir:  $1/" "NOT FOUND"; }

# Grep a file for an extended-regex pattern
file_has() {
    grep -qE "$2" "$3" 2>/dev/null \
        && ok "$1" \
        || ko "$1" "pattern not found: $2"
}

file_has_ci() {
    grep -qiE "$2" "$3" 2>/dev/null \
        && ok "$1" \
        || ko "$1" "pattern not found (case-insensitive): $2"
}

# Check that a file only imports modules from an allow-list.
# __future__ and typing are always tolerated (annotation plumbing).
check_imports() {
    local label="$1" file="$2" allowed="$3 __future__ typing"
    local offenders=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^import[[:space:]]+(.+) ]]; then
            local mods="${BASH_REMATCH[1]}"
            IFS=',' read -ra parts <<< "$mods"
            for p in "${parts[@]}"; do
                p="$(echo "$p" | sed -E 's/ as .*//' | xargs)"
                p="${p%%.*}"
                [ -n "$p" ] && ! grep -qw "$p" <<< "$allowed" && offenders="$offenders $p"
            done
        elif [[ "$line" =~ ^from[[:space:]]+([A-Za-z0-9_\.]+)[[:space:]]+import ]]; then
            local mod="${BASH_REMATCH[1]}"
            mod="${mod%%.*}"
            ! grep -qw "$mod" <<< "$allowed" && offenders="$offenders $mod"
        fi
    done < <(grep -E '^[[:space:]]*(import|from)[[:space:]]' "$file" 2>/dev/null | sed -E 's/^[[:space:]]+//')

    offenders="$(echo "$offenders" | xargs -n1 2>/dev/null | sort -u | xargs)"
    if [ -z "$offenders" ]; then
        ok "$label"
    else
        ko "$label" "unauthorized import(s):$offenders"
    fi
}

run_ok() {
    "$1" "$2" >/dev/null 2>&1 \
        && ok  "$3 — exits 0" \
        || ko  "$3 — exits 0" "non-zero exit code"
}

no_committed_venv() {
    local label="$1" dir="$2"
    local found=""
    for d in venv .venv env matrix_env bare_env; do
        [ -d "$dir/$d" ] && found="$found $dir/$d"
    done
    if [ -z "$found" ]; then
        ok "$label"
    else
        ko "$label" "found committed environment dir(s):$found"
    fi
}

# ── preflight ────────────────────────────────────────────────────

command -v python3 >/dev/null 2>&1 || { echo -e "${RED}ERROR: python3 not found.${NC}"; exit 1; }

echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║        The Matrix — Data Engineering Tester        ║"
echo "  ║                       v1.0                         ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}  ${DIM}Python : $(python3 --version 2>&1)${NC}"
echo -e   "  ${DIM}Dir    : $(pwd)${NC}"
[ -n "$VIRTUAL_ENV" ] && echo -e "  ${YELLOW}${DIM}Note   : you are currently inside a virtual environment ($VIRTUAL_ENV).${NC}" \
                       && echo -e "  ${YELLOW}${DIM}         The 'outside venv' checks below may be skewed — consider${NC}" \
                       && echo -e "  ${YELLOW}${DIM}         deactivating and re-running for a fully accurate pass.${NC}"

# ================================================================
# 1 · FILE STRUCTURE
# ================================================================
banner "1 · File Structure"

chk_dir  ex0
chk_file ex0/construct.py

chk_dir  ex1
chk_file ex1/loading.py
chk_file ex1/requirements.txt
chk_file ex1/pyproject.toml

chk_dir  ex2
chk_file ex2/oracle.py
chk_file ex2/.env.example
chk_file ex2/.gitignore

no_committed_venv "no virtual environment committed anywhere in repo" "."

# ================================================================
# 2 · EXERCISE 0 — ENTERING THE MATRIX (construct.py)
# ================================================================
banner "2 · Exercise 0: Entering the Matrix"

if [ -f ex0/construct.py ]; then
    check_imports "[ex0] only uses authorized modules (sys, os, site)" ex0/construct.py "sys os site"

    # --- scenario A: outside a virtual environment -------------------
    OUT_OUTSIDE=$(python3 ex0/construct.py 2>&1); EXIT_OUTSIDE=$?
    [ $EXIT_OUTSIDE -eq 0 ] \
        && ok "[ex0] outside venv → exits 0" \
        || ko "[ex0] outside venv → exits 0" "exit code $EXIT_OUTSIDE"

    printf '%s\n' "$OUT_OUTSIDE" | grep -qi "virtual" \
        && ok "[ex0] outside venv → output mentions virtual environment" \
        || ko "[ex0] outside venv → output mentions virtual environment"

    printf '%s\n' "$OUT_OUTSIDE" | grep -qiE "none detected|not detected|no virtual" \
        && ok "[ex0] outside venv → reports none detected" \
        || ko "[ex0] outside venv → reports none detected"

    printf '%s\n' "$OUT_OUTSIDE" | grep -q -- "-m venv" \
        && ok "[ex0] outside venv → gives venv creation instructions" \
        || ko "[ex0] outside venv → gives venv creation instructions" "expected something like 'python -m venv ...'"

    printf '%s\n' "$OUT_OUTSIDE" | grep -qi "activate" \
        && ok "[ex0] outside venv → gives activation instructions" \
        || ko "[ex0] outside venv → gives activation instructions"

    printf '%s\n' "$OUT_OUTSIDE" | grep -qi "global" \
        && ok "[ex0] outside venv → warns about the global environment" \
        || ko "[ex0] outside venv → warns about the global environment"

    # --- scenario B: inside a freshly-created virtual environment ----
    TMP_ROOT=$(mktemp -d)
    python3 -m venv "$TMP_ROOT/matrix_env" >/dev/null 2>&1
    VENV_PY="$TMP_ROOT/matrix_env/bin/python3"
    [ -x "$VENV_PY" ] || VENV_PY="$TMP_ROOT/matrix_env/Scripts/python.exe"

    if [ -x "$VENV_PY" ]; then
        OUT_INSIDE=$("$VENV_PY" ex0/construct.py 2>&1); EXIT_INSIDE=$?
        [ $EXIT_INSIDE -eq 0 ] \
            && ok "[ex0] inside venv → exits 0" \
            || ko "[ex0] inside venv → exits 0" "exit code $EXIT_INSIDE"

        printf '%s\n' "$OUT_INSIDE" | grep -qiE "matrix_env|virtual environment" \
            && ok "[ex0] inside venv → detects the environment" \
            || ko "[ex0] inside venv → detects the environment"

        printf '%s\n' "$OUT_INSIDE" | grep -qi "site-packages" \
            && ok "[ex0] inside venv → shows package install path" \
            || ko "[ex0] inside venv → shows package install path"

        if [ "$OUT_OUTSIDE" != "$OUT_INSIDE" ]; then
            ok "[ex0] output differs between the two scenarios"
        else
            ko "[ex0] output differs between the two scenarios" "identical output inside/outside venv"
        fi
    else
        ko "[ex0] could not create a temp venv to test the 'inside' scenario" "python3 -m venv failed"
    fi
    rm -rf "$TMP_ROOT"
else
    ko "[ex0] construct.py present" "skipping ex0 tests — file missing"
fi

# ================================================================
# 3 · EXERCISE 1 — LOADING PROGRAMS (loading.py)
# ================================================================
banner "3 · Exercise 1: Loading Programs"

if [ -f ex1/loading.py ]; then
    check_imports "[ex1] only uses authorized modules (pandas, requests, matplotlib, numpy, sys, importlib)" \
        ex1/loading.py "pandas requests matplotlib numpy sys importlib"

    file_has "[ex1] imports pandas"     "^[[:space:]]*(import pandas|from pandas)"     ex1/loading.py
    file_has "[ex1] imports numpy"      "^[[:space:]]*(import numpy|from numpy)"       ex1/loading.py
    file_has "[ex1] imports matplotlib" "^[[:space:]]*(import matplotlib|from matplotlib)" ex1/loading.py

    file_has "[ex1] numpy is used to generate the dataset" \
        "(np|numpy)\.(random|arange|linspace)" ex1/loading.py

    file_has_ci "[ex1] requirements.txt lists pandas"     "pandas"     ex1/requirements.txt
    file_has_ci "[ex1] requirements.txt lists numpy"      "numpy"      ex1/requirements.txt
    file_has_ci "[ex1] requirements.txt lists matplotlib" "matplotlib" ex1/requirements.txt

    file_has "[ex1] pyproject.toml has a [tool.poetry] section" "\[tool\.poetry\]" ex1/pyproject.toml
    file_has "[ex1] pyproject.toml lists pandas"     "pandas"     ex1/pyproject.toml
    file_has "[ex1] pyproject.toml lists numpy"      "numpy"      ex1/pyproject.toml
    file_has "[ex1] pyproject.toml lists matplotlib" "matplotlib" ex1/pyproject.toml

    file_has "[ex1] includes a package-version comparison" "__version__" ex1/loading.py

    # --- runtime test: all deps present -------------------------------
    if python3 -c "import pandas, numpy, matplotlib" >/dev/null 2>&1; then
        rm -f ex1/*.png 2>/dev/null
        OUT1=$(cd ex1 && python3 loading.py 2>&1); EXIT1=$?
        AFTER_PNG=$(find ex1 -maxdepth 1 -iname "*.png" 2>/dev/null | wc -l)

        [ $EXIT1 -eq 0 ] \
            && ok "[ex1] runs successfully with all deps installed" \
            || ko "[ex1] runs successfully with all deps installed" "exit code $EXIT1"

        printf '%s\n' "$OUT1" | grep -qiE "pandas|numpy|matplotlib" \
            && ok "[ex1] output reports checked packages" \
            || ko "[ex1] output reports checked packages"

        printf '%s\n' "$OUT1" | grep -qE "[0-9]+\.[0-9]+(\.[0-9]+)?" \
            && ok "[ex1] output shows installed package version numbers" \
            || ko "[ex1] output shows installed package version numbers"

        [ "$AFTER_PNG" -gt 0 ] \
            && ok "[ex1] generates a visualization (.png) file" \
            || ko "[ex1] generates a visualization (.png) file" "no .png found in ex1/ after running"
    else
        info "[ex1] pandas/numpy/matplotlib not installed here — skipping runtime checks"
        info "       (pip install -r ex1/requirements.txt to enable them)"
    fi

    # --- runtime test: bare venv, no deps at all -----------------------
    TMP2=$(mktemp -d)
    python3 -m venv "$TMP2/bare_env" >/dev/null 2>&1
    BAREPY="$TMP2/bare_env/bin/python3"
    [ -x "$BAREPY" ] || BAREPY="$TMP2/bare_env/Scripts/python.exe"

    if [ -x "$BAREPY" ]; then
        OUTBARE=$(cd ex1 && "$BAREPY" loading.py 2>&1)
        if printf '%s\n' "$OUTBARE" | grep -q "Traceback (most recent call last)"; then
            ko "[ex1] handles missing dependencies gracefully" "raw traceback shown instead of a friendly message"
        else
            ok "[ex1] handles missing dependencies gracefully"
        fi
        printf '%s\n' "$OUTBARE" | grep -qiE "pip install|poetry (add|install)" \
            && ok "[ex1] missing-deps message suggests pip/poetry install" \
            || ko "[ex1] missing-deps message suggests pip/poetry install"
    else
        ko "[ex1] could not create a bare venv for the missing-deps test" "python3 -m venv failed"
    fi
    rm -rf "$TMP2"

    info "flake8/mypy import errors are explicitly tolerated for this exercise (subject §V)"
else
    ko "[ex1] loading.py present" "skipping ex1 tests — file missing"
fi

# ================================================================
# 4 · EXERCISE 2 — ACCESSING THE MAINFRAME (oracle.py)
# ================================================================
banner "4 · Exercise 2: Accessing the Mainframe"

if [ -f ex2/oracle.py ]; then
    check_imports "[ex2] only uses authorized modules (os, sys, dotenv)" ex2/oracle.py "os sys dotenv"

    file_has "[ex2] uses python-dotenv (load_dotenv)" "load_dotenv" ex2/oracle.py

    file_has "[ex2] .env.example → MATRIX_MODE"    "MATRIX_MODE"    ex2/.env.example
    file_has "[ex2] .env.example → DATABASE_URL"   "DATABASE_URL"   ex2/.env.example
    file_has "[ex2] .env.example → API_KEY"        "API_KEY"        ex2/.env.example
    file_has "[ex2] .env.example → LOG_LEVEL"      "LOG_LEVEL"      ex2/.env.example
    file_has "[ex2] .env.example → ZION_ENDPOINT"  "ZION_ENDPOINT"  ex2/.env.example

    file_has "[ex2] .gitignore excludes .env" "(^|/)\.env$" ex2/.gitignore

    if python3 -c "import dotenv" >/dev/null 2>&1; then
        # --- scenario A: no .env present, no overrides ---------------
        OUTA=$(cd ex2 && rm -f .env && env -u MATRIX_MODE -u DATABASE_URL -u API_KEY -u LOG_LEVEL -u ZION_ENDPOINT python3 oracle.py 2>&1)
        EXITA=$?
        [ $EXITA -eq 0 ] \
            && ok "[ex2] runs without crashing when no config is present" \
            || ko "[ex2] runs without crashing when no config is present" "exit code $EXITA"

        printf '%s\n' "$OUTA" | grep -qiE "missing|default|warning" \
            && ok "[ex2] warns about missing configuration" \
            || ko "[ex2] warns about missing configuration"

        # --- scenario B: .env file copied from .env.example ----------
        OUTB=$(cd ex2 && cp .env.example .env && python3 oracle.py 2>&1)
        printf '%s\n' "$OUTB" | grep -qiE "development|production" \
            && ok "[ex2] loads MATRIX_MODE from .env file" \
            || ko "[ex2] loads MATRIX_MODE from .env file"

        # --- scenario C: env var override beats .env file ------------
        OUTC=$(cd ex2 && MATRIX_MODE=production API_KEY=secret123 python3 oracle.py 2>&1)
        printf '%s\n' "$OUTC" | grep -q "production" \
            && ok "[ex2] environment variables override .env values" \
            || ko "[ex2] environment variables override .env values"

        rm -f ex2/.env
    else
        info "[ex2] python-dotenv not installed here — skipping runtime checks"
        info "       (pip install python-dotenv to enable them)"
    fi
else
    ko "[ex2] oracle.py present" "skipping ex2 tests — file missing"
fi

# ================================================================
# 5 · FLAKE8
# ================================================================
banner "5 · Flake8 Style"

if ! command -v flake8 >/dev/null 2>&1; then
    info "flake8 not installed — skipping (pip install flake8)"
else
    while IFS= read -r -d '' f; do
        res=$(flake8 --max-line-length=100 "$f" 2>&1)
        if [[ "$f" == ex1/* ]]; then
            # subject §V: import errors tolerated in ex1 only
            res=$(printf '%s\n' "$res" | grep -v -E "F401|E402|F811|C0413")
        fi
        if [ -z "$res" ]; then
            ok "flake8 clean: $f"
        else
            ko "flake8: $f"
            printf '%s\n' "$res" | head -3 | sed 's/^/         /'
        fi
    done < <(find ex0 ex1 ex2 -maxdepth 1 -name "*.py" ! -path "*/__pycache__/*" -print0 2>/dev/null | sort -z)
fi

# ================================================================
# 6 · MYPY
# ================================================================
banner "6 · Mypy Type Annotations"

if ! command -v mypy >/dev/null 2>&1; then
    info "mypy not installed — skipping (pip install mypy)"
else
    res=$(mypy ex0 ex1 ex2 --ignore-missing-imports 2>&1)
    # ex1/loading.py may intentionally raise import-related errors (subject §V)
    unexpected=$(printf '%s\n' "$res" | grep "error:" | grep -v "ex1/loading.py" || true)
    if [ -z "$unexpected" ]; then
        ok "mypy — no unexpected type errors"
        info "any ex1/loading.py import errors are tolerated per subject §V"
    else
        n_errors=$(printf '%s\n' "$unexpected" | grep -c "error:" || true)
        ko "mypy — $n_errors unexpected error(s)"
        printf '%s\n' "$unexpected" | head -5 | sed 's/^/         /'
    fi
fi

# ================================================================
# SUMMARY
# ================================================================
TOTAL=$((PASS + FAIL))
echo ""
echo -e "${CYAN}${BOLD}══════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}  RESULTS${NC}"
echo -e "${CYAN}${BOLD}══════════════════════════════════════${NC}"
echo -e "  ${GREEN}Passed : $PASS${NC}"
echo -e "  ${RED}Failed : $FAIL${NC}"
echo -e "  Total  : $TOTAL"
echo -e "${CYAN}${BOLD}══════════════════════════════════════${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}💊  All tests passed! Welcome to the real world.${NC}"
else
    echo -e "  ${RED}${BOLD}🔴  $FAIL test(s) failed. The machines found a bug.${NC}"
fi
echo ""

exit $FAIL
