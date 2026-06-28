# OneWeave Handoff — Cycle 31 (2026-06-28)

> **Status:** Cycle 30 features complete + cycle 31 workflow refinements applied.
> Awaiting Mac handoff for compile-blocker resolution (M01-M44).

## What's New in Cycle 31

### Workflow Refinements (5 new skills)

These were discovered and codified during the cycle 30 → 31 reflection on
multi-CLI workflow gaps. Each is a leaf skill that composes with the existing
`multi-cli-coding-orchestration` parent.

| Skill | Purpose | Solves |
|---|---|---|
| `~/.hermes/skills/autonomous-ai-agents/cli-auth-preflight/` | Probe auth state for all 5 CLIs before dispatch | Catches Kimi OAuth expiry before silent 1-byte dispatch failure |
| `~/.hermes/skills/autonomous-ai-agents/oauth-refresh-wrapper/` | Auto-detect + recover from auth failures | Kimi device-code refresh, Codex API key writer, GLM model loader |
| `~/.hermes/skills/autonomous-ai-agents/multi-agent-squad-orchestration/` | Chain CLIs as a team via file-based handoff | Sequential multi-CLI workflows with audit trail |
| `~/.hermes/skills/autonomous-ai-agents/agent-instructing-agent/` | Per-CLI prompt reformatting | Tailor briefs to each CLI's training distribution (2-5x better outputs) |
| `~/.hermes/skills/autonomous-ai-agents/telegram-topic-routing/` | Multi-session parallel work via Telegram topics | 5 isolated work surfaces in one supergroup |

### Meta-Reflections Document

`~/.hermes/skills/autonomous-ai-agents/META_REFLECTIONS_2026-06-28.md` captures
the meta-frame: shipping OneWeave (privacy-first iOS app) AND shipping the
agentic workflow that builds it, in parallel. Each cycle dogfoods new patterns
into skills; the workflow is publishable as a reference architecture.

### Project-Side Changes

- `.cli/` folder created + gitignored — per-project CLI working folder
- `scripts/dispatch_oneweave.sh` — file-based per-CLI dispatcher (replaces inline `$(cat ...)` pattern)
- `scripts/dispatch_panel.sh` — 5-CLI parallel wrapper
- `.cli/context/wiki/` — 166 graphify-generated articles for CLI navigation
- `.cli/context/file_inventory.txt` — auto-generated file inventory
- `.cli/context/architecture_summary.md` — top god nodes + subsystem map

## Why These Skills Matter

The cycle 30 dispatch failed silently 3 times because of `$(cat prompt.md)`
shell substitution issues. Skills A + C (pre-flight + refresh) eliminate that
failure mode entirely. Skills B + E (squad + per-CLI briefs) enable the
next-generation workflow: Hermes as coordinator, 5 CLIs as a team, file-based
handoff with audit trail. Skill D (Telegram topics) enables parallel projects.

## How to Use the New Skills

### Next dispatch round (cycle 32+)

```bash
cd ~/hermes-workspace/projects/oneweave

# 1. Pre-flight (catches auth issues before they bite)
bash ~/.hermes/skills/autonomous-ai-agents/cli-auth-preflight/scripts/cli_auth_probe.sh

# 2. If any FAIL, refresh
bash ~/.hermes/skills/autonomous-ai-agents/oauth-refresh-wrapper/scripts/refresh_kimi.sh

# 3. Dispatch (file-based, auto-recovers from auth failures)
bash scripts/dispatch_with_preflight.sh claude .cli/prompts/round_5_claude.md .cli/outputs/round_5_claude.md

# Or use the retry wrapper that auto-recovers
bash ~/.hermes/skills/autonomous-ai-agents/oauth-refresh-wrapper/scripts/dispatch_with_retry.sh \
    kimi .cli/prompts/round_5_kimi.md .cli/outputs/round_5_kimi.md 2
```

### For a squad (sequential multi-CLI workflow)

```bash
# 1. Write MISSION.md to .cli/handoff/
cat > .cli/handoff/MISSION.md <<'EOF'
# Squad Mission: OneWeave cycle 32 — apply remaining Linux fixes

**Goal:** Apply T099-T146 Linux-fixable items
**Phases:**
1. Claude writes patches for T099-T110 → results/01_claude.md
2. Codex applies patches → results/02_codex.md
3. Kimi writes regression tests → results/03_kimi.md
4. Hermes runs validators + synthesis
EOF

# 2. Per-phase briefs go in .cli/handoff/briefs/NN_role.md
# 3. Run the squad loop (manual or via init_squad.sh)
```

## What's Left for Mac (M01-M44)

15 compile-blockers (per Grok cycle 30) + iOS-only features. Top priority:

- M01-M13: Swift type/signature fixes (`LifeContext.threads` type, etc.)
- M14-M22: iOS platform features (App Intents, Widgets, Live Activities)
- M23-M29: Notifications + Dynamic Island
- M31-M40: App Store submission

Full list: `tasks.md` M01-M44.

## Tarball

`/root/oneweave-cycle30-handoff-2026-06-28.tar.gz` (6.1 MB, 1,930 entries)
— refresh for cycle 32 once next round completes.

## Git History (cycles 29-31)

```
f87d71d feat(workflow): file-based CLI dispatcher + graphify wiki in .cli/context
7891018 chore(workflow): add .cli/ to .gitignore — per-project CLI working folder
652078c docs(cycle30): handoff update — 5-CLI synthesis applied + 11 Swift patches
b44fb02 feat(cycle30): multi-CLI synthesis + Linux-fixable apply (5 CLIs + Hermes)
b96c2a1 fix(cycle29): GLM 5.2 round-1 findings — 4 compile-blocker + privacy fixes
```
