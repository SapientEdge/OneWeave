# Contributing

Thanks for caring about privacy. This document explains how to make
changes that preserve the privacy guarantees.

## TL;DR

- Read [`PRIVACY.md`](./PRIVACY.md) before touching any code that
  handles user data.
- Run `bash .research/validate_all.sh` before every commit. All 11
  suites must pass.
- Any change to a public type listed in `OneWeaveAPI.swift` is a
  breaking change unless the `apiVersion` constant is bumped.
- This codebase is built on Linux + validated on Mac. Don't introduce
  changes that require Xcode-only testing.

## Setup

```bash
git clone <this repo>
cd oneweave
bash .research/validate_all.sh
```

You should see "ALL SUITES PASS" at the end. If you don't, something
in the test fixtures is stale.

## Where to make changes

| Want to...                          | Look at                                        |
|-------------------------------------|------------------------------------------------|
| Add a new SwiftData model           | `Sources/OneWeave/LifeContext.swift` + `SchemaMigrationPlan.swift` |
| Add a new privacy toggle            | `Sources/OneWeave/DataLeashSettings.swift`     |
| Add a new iOS system integration    | `Sources/OneWeave/iOSServiceIntegrations.swift` (always gated on Data Leash) |
| Add a new creative feature          | New file in `Sources/OneWeave/`, then add it to `OneWeaveAPI.swift` |
| Add a new P2P message type          | `Sources/OneWeave/P2PWeaveShare.swift` (reflection-gated) |
| Add a new Family Pod visibility grant | `Sources/OneWeave/FamilyPod.swift`           |
| Add a new validator / stress test   | New file `.research/validate_<name>.py`, add to `validate_all.sh` |

## The five privacy gates (preserved)

Any change that touches user data must preserve all five gates. If your
change cannot preserve a gate, that's a sign the feature shouldn't ship.

1. **Reflection gate** — every commit function takes a non-empty
   `reflectionText: String`.
2. **Data Leash gate** — every iOS integration reads the user's toggle
   BEFORE calling the framework.
3. **Consent gate** — `LifeEntity.isUserReflection: Bool` is the only
   way to mark content as user-authored.
4. **Sacred Echo unlock gate** — plaintext is decrypted only after
   `unlockAt <= now`; plaintext is never persisted.
5. **Fail-closed crypto gate** — no deterministic cipher seed in
   production code.

## Code style

- Swift: 4-space indent. Types `UpperCamelCase`. Functions and variables
  `lowerCamelCase`. Constants in enums `lowerCamelCase`.
- Prefer pure functions over `@MainActor` ones unless UI is required.
- Prefer value types (`struct`) over reference types (`class`) unless
  SwiftData `@Model` requires the latter.
- Prefer explicit `throws` over optional returns for failure paths.
- Comments at the top of every file explaining what it does and what
  it intentionally does NOT do.

## Testing

- New pure functions must have a Python behavior mirror in
  `.research/validate_*.py`.
- The harness runs on Linux without Swift runtime; mirror the algorithm
  in Python and exercise the same edge cases.
- Aim for: happy path + every documented invariant + every documented
  anti-pattern.

## Multi-agent reviews

When you open a PR, the three review agents (Grok, Claude Code,
Nemotron) will be dispatched against your diff. Their role-specialized
prompts are in `.research/AGENT_SQUAD_PROMPTS.md`. Findings are
applied automatically; you'll see them as commits before the PR merges.

If you want to pre-emptively apply known-good patterns, scan the
existing review trail in `.research/build_log.md`.

## Commit messages

Use the format:

```
<scope>: <imperative summary>

<body — what changed and why>

<reflection — how this preserves the five privacy gates>
```

Example:

```
sacred-echo: trim delivery reflection attributes

Plaintext delivery reflections were being persisted in the
echo.attributes bag. Per Nemotron cycle-27 #32, this is a privacy
leak — attributes live in the SQLite store and are not encrypted.

Refactor: store only the timestamp + a hash flag. The plaintext
remains in the in-session ritual only.

Preserves gate 4 (Sacred Echo unlock gate): plaintext is still never
persisted.
```

## Releases

- Bump `OneWeaveAPICatalog.apiVersion` for any public-API change.
- Bump `PortableExportPolicy.currentBundleVersion` for any
  export-format change (and add a migration path).
- Update `.research/build_log.md` with the release entry.

## Questions?

Open an issue. For security-sensitive questions (e.g., "is this a
privacy bypass?"), mark it `security` and we'll respond privately.