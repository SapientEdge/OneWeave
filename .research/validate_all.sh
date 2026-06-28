#!/usr/bin/env bash
# validate_all.sh — Run every Linux validation harness for OneWeave.
#
# Usage: bash .research/validate_all.sh
# Exit code: 0 if ALL tests pass; 1 if any fail.

set -u
cd "$(dirname "$0")/.."

echo "==========================================================================="
echo "OneWeave Linux validation — full suite"
echo "==========================================================================="
echo ""

TOTAL_PASS=0
TOTAL_FAIL=0
SUITE_COUNT=0
SUITE_PASS=0

# Scan both .research/ (existing) and audit/validators/ (new audit wrappers)
shopt -s nullglob
SUITES=(.research/validate_*.py audit/validators/validate_*.py)
shopt -u nullglob
for suite in "${SUITES[@]}"; do
    SUITE_COUNT=$((SUITE_COUNT + 1))
    name=$(basename "$suite" .py)
    echo ""
    echo "--- $name ---"
    output=$(python3 "$suite" 2>&1)
    echo "$output" | tail -10
    # Detection: a suite passes if its FULL output does NOT contain
    # "FAILED:" with a non-zero count. Some suites print "OVERALL: PASS"
    # instead of "Total: N | FAILED: 0" — handle both.
    if echo "$output" | grep -qE "OVERALL: PASS"; then
        SUITE_PASS=$((SUITE_PASS + 1))
    elif echo "$output" | tail -5 | grep -qE "FAILED: 0\b|PASSED: [0-9]+  \|  FAILED: 0"; then
        SUITE_PASS=$((SUITE_PASS + 1))
    else
        TOTAL_FAIL=1
    fi
done

echo ""
echo "==========================================================================="
echo "Summary"
echo "==========================================================================="
echo "Suites run: $SUITE_COUNT"
echo "Suites all-green: $SUITE_PASS"
echo "Suites with failures: $((SUITE_COUNT - SUITE_PASS))"
echo ""

if [ $TOTAL_FAIL -eq 0 ] && [ $SUITE_PASS -eq $SUITE_COUNT ]; then
    echo "✓ ALL SUITES PASS"
    exit 0
else
    echo "✗ AT LEAST ONE SUITE HAS FAILURES"
    exit 1
fi