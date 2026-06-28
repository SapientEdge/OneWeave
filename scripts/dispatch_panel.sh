#!/usr/bin/env bash
# dispatch_panel.sh — Fire all 5 CLIs in parallel (file-based)
#
# Companion to dispatch_oneweave.sh. Reads role-specialized prompts
# from .cli/prompts/round_N_<model>.md and writes outputs to
# .cli/outputs/round_N_<model>.md. Optionally takes a round prefix.
#
# Usage:
#   dispatch_panel.sh                  (defaults to round_N matching latest)
#   dispatch_panel.sh round_5          (uses round_5_* files)
#   dispatch_panel.sh round_5 --serial (run one at a time, not parallel)
#
# The 5-CLI panel pattern:
#   claude = production-readiness audit
#   grok   = compile-blocker + crash-risk hunt
#   codex  = iOS platform completeness (App Intents, widgets)
#   kimi   = test design (validators, property tests)
#   glm    = creative ideation (novel features, bold bet)

set -uo pipefail

ROUND="${1:-round_N}"
SERIAL="${2:-}"

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PROJECT_ROOT"

PROMPTS_DIR="$PROJECT_ROOT/.cli/prompts"
OUTPUTS_DIR="$PROJECT_ROOT/.cli/outputs"
mkdir -p "$PROMPTS_DIR" "$OUTPUTS_DIR"

CLIS=(claude grok codex kimi glm)

# Verify all 5 prompt files exist
missing=0
for cli in "${CLIS[@]}"; do
  prompt="$PROMPTS_DIR/${ROUND}_${cli}.md"
  if [[ ! -f "$prompt" ]]; then
    echo "[panel] MISSING prompt: $prompt" >&2
    missing=$((missing+1))
  fi
done
if [[ $missing -gt 0 ]]; then
  echo "[panel] $missing prompt file(s) missing. Create them in $PROMPTS_DIR first." >&2
  exit 5
fi

echo "[panel] Dispatching 5 CLIs in parallel (round=$ROUND)"
echo "[panel] Working dir: $PROJECT_ROOT"
echo ""

run_one() {
  local cli="$1"
  local prompt="$PROMPTS_DIR/${ROUND}_${cli}.md"
  local output="$OUTPUTS_DIR/${ROUND}_${cli}.md"
  "$PROJECT_ROOT/scripts/dispatch_oneweave.sh" "$cli" "$prompt" "$output"
}

if [[ "$SERIAL" == "--serial" ]]; then
  echo "[panel] Serial mode"
  for cli in "${CLIS[@]}"; do
    run_one "$cli"
  done
else
  echo "[panel] Parallel mode (5 jobs)"
  for cli in "${CLIS[@]}"; do
    run_one "$cli" &
  done
  wait
fi

echo ""
echo "[panel] Round $ROUND complete. Summary:"
echo ""
printf '%-12s %10s  %s\n' "CLI" "BYTES" "OUTPUT"
printf '%-12s %10s  %s\n' "---" "-----" "------"
total=0
for cli in "${CLIS[@]}"; do
  output="$OUTPUTS_DIR/${ROUND}_${cli}.md"
  if [[ -f "$output" ]]; then
    size=$(wc -c < "$output")
    total=$((total + size))
    printf '%-12s %10d  %s\n' "$cli" "$size" "$output"
  fi
done
echo ""
echo "[panel] Total: $total bytes across 5 outputs"
echo ""
echo "[panel] Next step: read each output, run cross-verification triage."
echo "[panel] See ~/.hermes/skills/autonomous-ai-agents/multi-cli-coding-orchestration"
echo "[panel] section 'Cross-Verification Is Non-Negotiable' for the workflow."
