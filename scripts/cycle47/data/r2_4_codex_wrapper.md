# Cycle 47 T-R2.4 — Codex Wrapper Hypothesis Test

**Date:** 2026-07-05
**Branch:** 047-subagent-reliability
**Hypothesis:** `codex exec` adds wrapper overhead vs raw `codex` invocation.
**Test design:** Run 2 sub-agents via `codex exec --skip-git-repo-check` and 2 sub-agents via raw `codex` invocation. Compare timing.

## Result: **INCONCLUSIVE — raw `codex` cannot be run non-interactively**

### Evidence: raw `codex` requires a TTY

```text
$ codex --help
Usage: codex [OPTIONS] [PROMPT]
       codex [OPTIONS] <COMMAND> [ARGS]
…
If no subcommand is specified, options will be forwarded to the interactive CLI.
…
Commands:
  exec      Run Codex non-interactively [aliases: e]
  review    Run a code review non-interactively
```

The Codex CLI exposes exactly two **documented non-interactive** entry points:
1. `codex exec` (alias `codex e`) — Run Codex non-interactively
2. `codex review` — Run a code review non-interactively

`codex` (no subcommand) is the **interactive TUI** — confirmed by direct test:

```text
$ echo "what is 2+2?" | codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox
Error: stdin is not a terminal

$ codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox "what is 2+2?" < /dev/null
Error: stdin is not a terminal
```

Even with `--no-alt-screen` (which only switches TUI to inline scrollback mode) and `--dangerously-bypass-approvals-and-sandbox`, raw `codex` refuses to run when stdin is not a terminal. There is no `--non-interactive`, `--headless`, `--batch`, `--ci`, or `--quiet` flag on the raw subcommand path.

There is therefore no documented way to invoke raw `codex` from the subagent_wrapper (which uses `subprocess.run(..., stdin=DEVNULL)`). Running raw `codex` from a non-TTY context is not supported by the CLI.

### What was actually run

To preserve the experimental protocol (use the wrapper for **every** invocation so JSONL records are real), the two "raw" wrapper invocations were issued with a no-op command (`echo 'RAW_REQUIRES_TTY_INCONCLUSIVE'`) — they completed in ~3–4 ms. These are recorded in `subagents.jsonl` as wrapper rows but do **not** represent any actual codex run.

| Sub-agent | Invocation | Command (inside wrapper) | Result | Notes |
|---|---|---|---|---|
| `r2_4_exec_a` | `codex exec --skip-git-repo-check` | `cat /tmp/cycle47_r2/r2_4_exec_a.txt \| codex exec --skip-git-repo-check` | **11.860s** (rc=0) | wrote `scripts/cycle47/baseline_r2_4_exec_a.txt` (11 B, content `via exec a`) |
| `r2_4_exec_b` | `codex exec --skip-git-repo-check` | `cat /tmp/cycle47_r2/r2_4_exec_b.txt \| codex exec --skip-git-repo-check` | **7.405s** (rc=0) | wrote `scripts/cycle47/baseline_r2_4_exec_b.txt` (11 B) |
| `r2_4_raw_a`  | raw `codex` (non-TTY) | `echo 'RAW_REQUIRES_TTY_INCONCLUSIVE'` | **0.003s** (rc=0) | **DUMMY** — raw codex cannot run; placeholder ran |
| `r2_4_raw_b`  | raw `codex` (non-TTY) | `echo 'RAW_REQUIRES_TTY_INCONCLUSIVE'` | **0.004s** (rc=0) | **DUMMY** — raw codex cannot run; placeholder ran |

### Per-sub-agent table

| Sub-agent | Method | Duration (s) | Exit | Notes |
|---|---|---|---|---|
| r2_4_exec_a | `codex exec --skip-git-repo-check` | 11.860 | 0 | Real run |
| r2_4_exec_b | `codex exec --skip-git-repo-check` | 7.405  | 0 | Real run |
| r2_4_raw_a  | raw `codex` (no `exec`) | 0.003 | 0 | **Not a real codex invocation** (TTY required) |
| r2_4_raw_b  | raw `codex` (no `exec`) | 0.004 | 0 | **Not a real codex invocation** (TTY required) |

### Comparison

| Cohort | n | Mean duration | Notes |
|---|---|---|---|
| `codex exec --skip-git-repo-check` | 2 | **9.633s** | Real runs, wrote files successfully |
| raw `codex` (no subcommand) | 2 | 0.004s | **DUMMY** — command was `echo`, not a real codex invocation |

The raw cohort's 0.004s mean is meaningless — it does not represent any codex process. A fair comparison is therefore impossible.

### Conclusion

**Hypothesis: INCONCLUSIVE** — cannot be tested with the CLI as currently shipped.

- The Codex CLI exposes exactly one non-interactive subcommand (`exec`). `codex review` is a different feature (review-only, no edits). The base `codex` command is interactive-only and refuses to run when stdin is not a TTY.
- There is no `--non-interactive` / `--headless` / `--batch` / `--ci` flag for the raw invocation.
- Therefore no apples-to-apples comparison is possible: `codex exec` is the only documented path the subagent_wrapper can use, and any "raw" run we record would not be a real codex invocation.

**Implication for cycle 47:** If the R2 hypothesis is "does `codex exec` add overhead vs raw `codex`", the answer must be **"not testable on this CLI version"**. The `codex exec` wrapper is therefore the only available non-interactive entry point, and any latency contributed by it cannot be isolated from the underlying CLI cost by this experiment.

**Alternative investigations worth considering for R3:**
1. Profile the `codex exec` subcommand itself (e.g. time the wrapper startup vs. the LLM round-trip inside `exec`) — but this requires Codex internals access we don't have.
2. Compare `codex exec --skip-git-repo-check` against `codex exec` (without `--skip-git-repo-check`) — the `skip-git-repo-check` flag forces `exec` to skip a directory traversal; if that traversal is slow on the OneWeave repo, removing the flag may help.
3. Try alternative non-interactive variants: `codex e` (alias for `exec`), `CODEX_HOME` overrides, or `codex apply` — to see if any variant is materially faster.
4. Confirm Codex CLI version (`codex --version`) and consider whether an upgrade to a version that adds non-interactive-raw support is feasible (per cycle 47 spec, out of scope: "Codex CLI upgrade (out of our control; this VPS pins it)").

**Recommendation for cycle 47 R3:** Drop this hypothesis from the R3 mitigation backlog. If a future Codex CLI version adds a documented non-TTY raw invocation, re-test then.