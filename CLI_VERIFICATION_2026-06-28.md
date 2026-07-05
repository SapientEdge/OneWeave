# OneWeave — Multi-CLI Verification Matrix

**Verified:** 2026-06-28 · **Branch:** 002-gamification

## All 7 Agents Operational

| # | Agent | Model | CLI | Probe Log | Notes |
|---|-------|-------|-----|-----------|-------|
| 1 | **MiniMax M3** (orchestrator) | `MiniMax-M3` | n/a (Hermes native) | this session | Coordinates all subagents |
| 2 | **Claude Code** | `claude-opus-4-8` | `claude` v2.1.195 | `/tmp/cli_probe_claude.log` | `claude -p "..." </dev/null` |
| 3 | **OpenAI Codex** | `gpt-5-codex` | `codex` v0.142.3 | `/tmp/cli_probe_codex.log` | **REQUIRES `--skip-git-repo-check`** outside trusted dirs |
| 4 | **Grok** | `Grok 4.3` | `grok` (headless via flags) | `/tmp/cli_probe_grok.log` | `grok --no-plan --single "..." --cwd <dir>` |
| 5 | **GLM 5.2** (Z.ai) | `GLM-4 family` (cloud) | `ollama run glm-5.2:cloud` | `/tmp/cli_probe_glm.log` | Ollama cloud; benign manifest warning |
| 6 | **Nemotron 3 Ultra** (NVIDIA) | `Nemotron 3 Ultra` (cloud) | `ollama run nemotron-3-ultra:cloud` | `/tmp/cli_probe_nemotron.log` | Ollama cloud; first activation today |
| 7 | **Kimi K2.5** (Moonshot) | `Kimi K2.5` | `kimi` v1.48.0 | `/tmp/cli_probe_kimi.log` | Fresh login 2026-06-28; credentials at `~/.kimi/credentials/kimi-code.json` |

## Known Caveats

- **Codex requires `--skip-git-repo-check`** outside trusted dirs. Workaround added to all dispatch scripts.
- **Ollama cloud models log "failed to pull manifest" warning** — this is benign; the model runs anyway via the cloud stub.
- **Grok on Linux** prefers `grok --no-plan --single --cwd <dir>` for headless. Avoid `grok-build` (clips output to ~1KB).
- **Kimi probe** can over-think on identity questions and timeout. Use concise prompts for verification.
- **GLM 5.2 self-identity** may confabulate ("GLM-4" vs "GLM-4.6"); actual model is `glm-5.2:cloud` per ollama list.

## Dispatch Pattern

All 5 external CLIs use the file-based I/O pattern at `.cli/{prompts,outputs}/`:

```bash
# Claude
timeout 600 claude -p "$(cat .cli/prompts/round_X_claude.md)" </dev/null > .cli/outputs/round_X_claude.md 2>&1

# Codex (note: --skip-git-repo-check)
timeout 600 codex exec --skip-git-repo-check "$(cat .cli/prompts/round_X_codex.md)" </dev/null > .cli/outputs/round_X_codex.md 2>&1

# Grok (note: --cwd)
cd /root/hermes-workspace/projects/oneweave && timeout 600 grok --no-plan --single "$(cat .cli/prompts/round_X_grok.md)" --cwd /root/hermes-workspace/projects/oneweave > .cli/outputs/round_X_grok.md 2>&1

# GLM 5.2 (Ollama cloud)
timeout 600 ollama run glm-5.2:cloud "$(cat .cli/prompts/round_X_glm.md)" > .cli/outputs/round_X_glm.md 2>&1

# Nemotron 3 Ultra (Ollama cloud)
timeout 600 ollama run nemotron-3-ultra:cloud "$(cat .cli/prompts/round_X_nemotron.md)" > .cli/outputs/round_X_nemotron.md 2>&1
```

## Multi-CLI Review Pattern

Each CLI is weighted differently in the synthesis:

| CLI | Weight | Lens |
|-----|--------|------|
| Claude | Constitutional | Privacy, anti-engagement, reflection gates |
| Codex | Correctness | Type safety, error paths, edge cases |
| Grok | Architecture | Patterns, abstractions, scaling |
| GLM | Creative | Novel features, naming, user experience |
| Nemotron | Adversarial | Race conditions, security holes, attack vectors |

Consensus findings (raised by 3+ CLIs) get highest priority in the unified fix list.
