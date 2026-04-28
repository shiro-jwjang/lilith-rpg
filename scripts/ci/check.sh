#!/usr/bin/env bash
# CI gate: static analysis + test
# Returns non-zero on failure so pre-push hook / CI can block
set -uo pipefail

GODOT="${GODOT:-godot}"

echo "═══ Lilith RPG CI Gate ═══"
echo ""

# 1. GDScript static analysis (parse/type errors)
echo "▶ Step 1: GDScript static analysis..."
ANALYSIS=$($GODOT --headless --quit --check-only 2>&1 || true)
if echo "$ANALYSIS" | grep -qi "Parse Error"; then
  echo "  ❌ Parse errors detected:"
  echo "$ANALYSIS" | grep -i "Parse Error"
  exit 1
fi
echo "  ✅ No parse errors"

# 2. Tests
echo "▶ Step 2: Running tests..."
TEST_OUTPUT=$($GODOT --headless --script test/test_runner.gd 2>&1 || true)
SUMMARY=$(echo "$TEST_OUTPUT" | grep -E "Results:|passed|failed" | tail -3)
echo "$SUMMARY"

if echo "$TEST_OUTPUT" | grep -q "SOME TESTS FAILED"; then
  echo ""
  echo "  ❌ Test failures:"
  echo "$TEST_OUTPUT" | grep "❌"
  exit 1
fi

if echo "$TEST_OUTPUT" | grep -q "ALL TESTS PASSED"; then
  echo ""
  echo "═══ ✅ All checks passed ═══"
  exit 0
fi

echo ""
echo "⚠️  Could not determine test result. Assuming failure."
exit 1
