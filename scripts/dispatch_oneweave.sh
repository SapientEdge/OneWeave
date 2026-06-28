#!/usr/bin/env bash
# dispatch_oneweave.sh — File-based OneWeave CLI dispatcher
#
# Reads prompts and writes outputs to the per-project .cli/ folder.
# Uses FILE PATHS (not inline text) to avoid the $(cat ...) shell
# substitution failures seen in cycle 30 (grok=1 byte, glm=979 bytes).
#
# Usage:
#   dispatch_oneweave.sh <cli> <prompt_file> <output_file>
#
#   cli: claude | grok | codex | kimi | glm
#   prompt_file: path to the prompt (relative to project root or absolute)
#   output_file: where to write the CLI's response
#
# Project conventions (OneWeave):
#   .cli/prompts/round_N_<model>.md   (the prompt)
#   .cli/outputs/round_N_<model>.md   (the response)
#   .cli/context/                      (file inventory + wiki + images)
#
# The dispatcher ALWAYS cd's into the project root first so the CLI
# sees only project files. NO_TRAINING prefix is prepended from
# .research/NO_TRAINING_PROMPT.md if present.

set -euo pipefail

CLI="${1:-}"
PROMPT_FILE="${2:-}"
OUT_FILE="${3:-}"

if [[ -z "$CLI" || -z "$PROMPT_FILE" || -z "$OUT_FILE" ]]; then
  cat <<'USAGE' >&2
Usage: dispatch_oneweave.sh <cli> <prompt_file> <output_file>

Examples:
  dispatch_oneweave.sh claude .cli/prompts/round_5_claude.md .cli/outputs/round_5_claude.md
  dispatch_oneweave.sh grok   .cli/prompts/round_5_grok.md   .cli/outputs/round_5_grok.md
  dispatch_oneweave.sh codex  .cli/prompts/round_5_codex.md  .cli/outputs/round_5_codex.md
  dispatch_oneweave.sh kimi   .cli/prompts/round_5_kimi.md   .cli/outputs/round_5_kimi.md
  dispatch_oneweave.sh glm    .cli/prompts/round_5_glm.md    .cli/outputs/round_5_glm.md

CLIs:
  claude -p with --add-dir to project root
  grok   --single <prompt> --no-plan --cwd <project>
  codex  exec with stdin pipe (works with file redirects)
  kimi   --print with --work-dir and stdin pipe
  glm    ollama run with prompt + context bundle inline (no file access)

The dispatcher automatically prepends a no-training privacy prefix from
.research/NO_TRAINING_PROMPT.md if it exists.
USAGE
  exit 2
fi

# Locate project root (where .cli/ lives)
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Resolve prompt/output paths relative to project root
if [[ "$PROMPT_FILE" != /* ]]; then
  PROMPT_FILE="$PROJECT_ROOT/$PROMPT_FILE"
fi
if [[ "$OUT_FILE" != /* ]]; then
  OUT_FILE="$PROJECT_ROOT/$OUT_FILE"
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "[dispatch_oneweave] ERROR: prompt file not found: $PROMPT_FILE" >&2
  exit 3
fi

# Make sure output dir exists
mkdir -p "$(dirname "$OUT_FILE")"

# Build combined prompt (with optional no-training prefix) in a temp file
TMP_PROMPT="$(mktemp -t oneweave_dispatch.XXXXXX)"
trap 'rm -f "$TMP_PROMPT"' EXIT

NO_TRAIN_FILE=""
for cand in "$PROJECT_ROOT/.research/NO_TRAINING_PROMPT.md" "$PROJECT_ROOT/NO_TRAINING_PROMPT.md"; do
  if [[ -f "$cand" ]]; then
    NO_TRAIN_FILE="$cand"
    break
  fi
done

if [[ -n "$NO_TRAIN_FILE" ]]; then
  # Strip lines starting with '#' to avoid CLI argument-parser confusion
  PRIVACY_HEADER="$(grep -v '^#' "$NO_TRAIN_FILE" 2>/dev/null || true)"
  {
    echo "=== PRIVACY: NO-TRAINING (must honor) ==="
    echo "$PRIVACY_HEADER"
    echo "=== END NO-TRAINING PREFIX ==="
    echo ""
    cat "$PROMPT_FILE"
  } > "$TMP_PROMPT"
else
  cp "$PROMPT_FILE" "$TMP_PROMPT"
fi

PROMPT_SIZE=$(wc -c < "$TMP_PROMPT")
echo "[dispatch_oneweave] $CLI: prompt=$PROMPT_FILE ($PROMPT_SIZE bytes) -> $OUT_FILE"

# Dispatch — ALWAYS cd into project root first
cd "$PROJECT_ROOT"

case "$CLI" in
  claude)
    # Claude: -p with prompt text. --add-dir so it sees project files.
    # --dangerously-skip-permissions is BLOCKED on root; omit.
    # Use --prompt-file to avoid shell-escape failures with $(cat ...).
    if /root/.local/bin/claude --help 2>&1 | grep -q -- "--prompt-file"; then
      /root/.local/bin/claude -p --prompt-file "$TMP_PROMPT" \
        --add-dir "$PROJECT_ROOT" \
        > "$OUT_FILE" 2>&1 || echo "[dispatch_oneweave] claude rc=$?" >> "$OUT_FILE"
    else
      /root/.local/bin/claude -p "$(cat "$TMP_PROMPT")" \
        --add-dir "$PROJECT_ROOT" \
        > "$OUT_FILE" 2>&1 || echo "[dispatch_oneweave] claude rc=$?" >> "$OUT_FILE"
    fi
    ;;

  grok)
    # Grok: --prompt-file is the correct flag for file-based prompts.
    # --single has an internal prompt-length limit and silently fails on long prompts.
    if /root/.local/bin/grok --help 2>&1 | grep -q -- "--prompt-file"; then
      /root/.local/bin/grok --prompt-file "$TMP_PROMPT" \
        --no-plan --cwd "$PROJECT_ROOT" \
        > "$OUT_FILE" 2>&1 || echo "[dispatch_oneweave] grok rc=$?" >> "$OUT_FILE"
    else
      /root/.local/bin/grok --single "$(cat "$TMP_PROMPT")" \
        --no-plan --cwd "$PROJECT_ROOT" \
        > "$OUT_FILE" 2>&1 || echo "[dispatch_oneweave] grok rc=$?" >> "$OUT_FILE"
    fi
    ;;

  codex)
    # Codex: stdin pipe via exec -; --skip-git-repo-check for non-root dirs
    /root/.local/bin/codex exec --skip-git-repo-check - \
      < "$TMP_PROMPT" \
      > "$OUT_FILE" 2>&1 || echo "[dispatch_oneweave] codex rc=$? (401=no OpenAI key)" >> "$OUT_FILE"
    ;;

  kimi)
    # Kimi: stdin pipe with --print + --yolo (auto-approve). OAuth may need refresh.
    /root/.local/bin/kimi --print \
      --work-dir "$PROJECT_ROOT" \
      -m kimi-code/kimi-for-coding \
      --final-message-only --yolo \
      < "$TMP_PROMPT" \
      > "$OUT_FILE" 2>&1 || echo "[dispatch_oneweave] kimi rc=$? (LLM not set? check ~/.kimi/credentials)" >> "$OUT_FILE"
    ;;

  glm)
    # GLM (chat-completion via Ollama): no tool access. Combine prompt with
    # file inventory so GLM has context.
    OLLAMA_BIN="$(command -v ollama || echo /usr/local/bin/ollama)"
    CONTEXT_FILE="$PROJECT_ROOT/.cli/context/file_inventory.txt"
    if [[ -f "$CONTEXT_FILE" ]]; then
      COMBINED="$(cat "$TMP_PROMPT")\n\n=== FILE INVENTORY ===\n$(cat "$CONTEXT_FILE")"
      printf '%b' "$COMBINED" \
        | "$OLLAMA_BIN" run glm-5.2:cloud - \
        > "$OUT_FILE" 2>&1 || echo "[dispatch_oneweave] glm rc=$?" >> "$OUT_FILE"
    else
      cat "$TMP_PROMPT" \
        | "$OLLAMA_BIN" run glm-5.2:cloud - \
        > "$OUT_FILE" 2>&1 || echo "[dispatch_oneweave] glm rc=$?" >> "$OUT_FILE"
    fi
    ;;

  *)
    echo "[dispatch_oneweave] Unknown CLI: $CLI" >&2
    exit 4
    ;;
esac

OUT_SIZE=$(wc -c < "$OUT_FILE" 2>/dev/null || echo 0)
echo "[dispatch_oneweave] $CLI: done ($OUT_SIZE bytes)"

# Sanity check — empty output usually means shell substitution or auth failure
if [[ "$OUT_SIZE" -lt 100 ]]; then
  echo "[dispatch_oneweave] WARNING: $OUT_FILE is suspiciously small ($OUT_SIZE bytes)" >&2
  echo "[dispatch_oneweave] Check for: CLI usage error, expired OAuth, missing API key, shell escape" >&2
fi
