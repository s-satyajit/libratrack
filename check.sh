#!/usr/bin/env bash
# check.sh - Build and run the public test for a specific issue
# Usage: ./check.sh <issue-number>
# Example: ./check.sh 5   or   ./check.sh 42

set -e

BOLD="\033[1m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# ── Argument validation ───────────────────────────────────────────────────────
if [[ -z "$1" ]]; then
    echo -e "${RED}Usage: ./check.sh <issue-number>${RESET}"
    echo -e "  Example: ${CYAN}./check.sh 5${RESET}"
    exit 1
fi

# Normalise to zero-padded two-digit string (1 → 01, 42 → 42)
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: issue number must be a positive integer (got: '$1')${RESET}"
    exit 1
fi

NUM=$(( 10#$1 ))   # strip any leading zeros passed in

if [[ $NUM -lt 1 || $NUM -gt 60 ]]; then
    echo -e "${RED}Error: issue number must be between 1 and 60 (got: $NUM)${RESET}"
    exit 1
fi

NN=$(printf "%02d" "$NUM")
TEST_FILTER="Issue${NN}_Public"

echo -e "${CYAN}${BOLD}+======================================+${RESET}"
echo -e "${CYAN}${BOLD}|   LibraTrack - Issue #${NN} checker     |${RESET}"
echo -e "${CYAN}${BOLD}+======================================+${RESET}"
echo ""

# ── Check build dir exists ────────────────────────────────────────────────────
if [[ ! -d "build" ]]; then
    echo -e "${YELLOW}Build directory not found. Running setup first...${RESET}"
    echo ""
    bash setup.sh
fi

# ── Rebuild to pick up student's latest changes ───────────────────────────────
echo -e "${BOLD}Building...${RESET}"
BUILD_OUTPUT=$(cmake --build build --parallel 2>&1)
BUILD_EXIT=$?

if [[ $BUILD_EXIT -ne 0 ]]; then
    echo ""
    echo -e "${RED}${BOLD}  [X] Build failed - fix the compile errors below:${RESET}"
    echo ""
    echo "$BUILD_OUTPUT" | grep -E "error:|warning:|note:" | head -30
    echo ""
    echo "$BUILD_OUTPUT" | tail -10
    exit 1
fi

echo -e "${GREEN}  [OK] Build succeeded${RESET}"
echo ""

# ── Run the test ──────────────────────────────────────────────────────────────
echo -e "${BOLD}Running tests for Issue #${NN}...${RESET}"
echo ""

# Capture ctest output; don't exit on failure (we handle it)
set +e
TEST_OUTPUT=$(ctest --test-dir build -R "^${TEST_FILTER}" --output-on-failure 2>&1)
TEST_EXIT=$?
set -e

# Print output with light indentation, skip only the noisy "Internal ctest" line
echo "$TEST_OUTPUT" | grep -v "^Internal ctest" | sed 's/^/  /'

echo ""
echo -e "------------------------------------------"

if [[ $TEST_EXIT -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}  [OK] All tests for Issue #${NN} PASSED!${RESET}"
    echo -e "${GREEN}       Your fix is working correctly.${RESET}"
else
    echo -e "${RED}${BOLD}  [X]  Tests for Issue #${NN} FAILED.${RESET}"
    echo -e "${YELLOW}       Review the output above - the 'Actual' vs 'Expected'${RESET}"
    echo -e "${YELLOW}       lines show exactly what your code returned.${RESET}"
fi

echo -e "------------------------------------------"
echo ""

exit $TEST_EXIT
