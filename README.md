# OneWeave

**A calm, privacy-first Life OS that treats your reflections like a conversation with your future self.**

OneWeave is a SwiftUI + SwiftData iOS application (iOS 17+) that models your life as a graph of entities, threads, and patterns. Every reflection you write becomes part of an encrypted, local-first knowledge graph — one that talks back to you via an "Invisible Mentor" powered entirely by your own past words.

The app is built around five creative features that no other journaling / life-tracking app combines:

1. **Life Graph** — your entities + relationships, with vector search, pattern detection, and privacy-tier filtering.
2. **Sacred Echo Vault** — AES-256-GCM encrypted time capsules. Write today, decrypt in a year. Includes Echo Decree (present-self → future-self) and Echo Heir (P2P hand-delivery).
3. **Invisible Mentor** — a deterministic synthesizer that quotes your own past reflections back to you when you ask a question. No LLM, no network — just you, talking to yourself across time.
4. **Resonance Oracle** — a local decision simulator that helps you compare choices by replaying your past patterns.
5. **Body-Thread Weaver** — graded HealthKit integration that maps bodily state to coherence, with a "Weave Pause" gate that prevents commitment under depletion.

Plus: Privacy Data Leash controls, Universal Command Palette, Cross-Domain Insight Engine (including a Contradiction Weaver), Family Pod (private anti-social family sharing), Living Graph Loom visualization, full SwiftData schema migration plan, and a portable export bundle that respects privacy leashes.

Plus 5 more high-value features delivered June 2026:

6. **Cognitive Load Score** — real-time estimate of overload, with **Weave Pause** (a reflection-gated gate that slows you down before commitment under load).
7. **Daily Briefings** — Morning Briefing (calendar + priorities + echoes + load) and Evening Review (recap + reflection prompt).
8. **Relationship Decay Tracker** — gentle prompts when you haven't connected with someone per your cadence.
9. **Decision Log** — capture reasoning + expected outcome; record actual outcome later; Invisible Mentor cites your past decisions.
10. **Quick Capture Inbox** — one text field, auto-routes to task / event / journal / decision / note via heuristic classifier.

---

## What this repo contains

This is the **Linux-developed reference implementation** of the OneWeave module. The codebase is built and validated on a Linux VPS (no Xcode, no simulator); the Mac-side Xcode project is scaffolded by following [`FIRST_WEEK_ON_MAC.md`](./FIRST_WEEK_ON_MAC.md) (human checklist) or [`CLAUDE_COWORK_BRIEF.md`](./CLAUDE_COWORK_BRIEF.md) (Claude brief).

**At a glance:**

- **55 Swift files** in `Sources/OneWeave/` (~15,700 lines)
- **11 SwiftData @Model types** with a VersionedSchema migration plan
- **16 Python validation suites** in `.research/validate_*.py` (525+ individual checks, all passing on Linux)
- **3 multi-agent reviews** already applied (Grok, Claude Code, Nemotron — 30+ issues found and fixed)
- **Zero external API dependencies** for core features (no cloud, no LLM, no telemetry)
- **Strict no-training contract** enforced via `.research/NO_TRAINING_PROMPT.md`
- **Market research round 3** (2026) included — competitive analysis of Day One, Reflectly, Stoic, Apple Journal, Bear

---

## Quick start

### For Mac-side developers (Xcode)

1. Read [`CLAUDE_COWORK_BRIEF.md`](./CLAUDE_COWORK_BRIEF.md) — this is the onboarding document.
2. Follow the 8-phase playbook in [`.research/TIER_B_PLAYBOOK.md`](./.research/TIER_B_PLAYBOOK.md).
3. Run `bash .research/validate_all.sh` to confirm the Linux-validated tests still pass after Mac build.
4. See [`MANIFEST.md`](./MANIFEST.md) for a one-line description of every file.

### For Linux developers (validation only)

```bash
cd /path/to/oneweave
bash .research/validate_all.sh   # 11 suites, 350+ checks
```

This runs every Python behavior mirror in `.research/`. All suites pass. The mirrors exercise the same algorithms the Swift code uses; on macOS the Swift code itself runs against the real types.

### For privacy / security reviewers

Read [`PRIVACY.md`](./PRIVACY.md) for the threat model, the five privacy gates (reflection / Data Leash / consent / isUserReflection / fail-closed crypto), and the explicit anti-patterns the app refuses to ship.

---

## Architecture

See [`ARCHITECTURE.md`](./ARCHITECTURE.md) for the full diagram and module map. Brief summary:

```
OneWeave (SwiftUI app, iOS 17+)
├── Core state layer (LifeContext, LifeGraph, threads)
├── Privacy + Data Leash (consulted BEFORE every integration)
├── Creative features (Sacred Echo, Mentor, Oracle, Body Thread, Living Loom)
├── Insights + Contradiction Weaver (cached, reflection-gated)
├── P2P layer (Network framework, WebRTC, BLE, offline queue, reflection gate)
├── Family Pod (private anti-social sharing, ≤6 people, quiet hours)
├── Portable Export (markdown + OPML + JSON, privacy-leash aware)
├── Schema migration plan (VersionedSchema + lightweight stages)
└── App lifecycle (encrypted envelope, scenePhase routing)
```

The full public API catalog lives in `Sources/OneWeave/OneWeaveAPI.swift`.

---

## Privacy commitments

The five privacy gates, enforced at the type level:

1. **Reflection gate** — every commitment action (quest completion, P2P receive, insight award, command palette commit, Sacred Echo open/deliver, Weave Pause, Invisible Mentor synthesis) requires a non-empty `reflectionText`.
2. **Data Leash gate** — every iOS system integration (Calendar, Contacts, HealthKit, Reminders, Mail, Notes, Body Thread, P2P, Insight awards) reads the user's actual toggle from `ModelContainer` BEFORE any data access.
3. **Consent gate** — InvisibleMentor only synthesizes from `LifeEntity.isUserReflection == true` (system content can never be misattributed as the user's words).
4. **isUserReflection gate** — Sacred Echo plaintext is decrypted only after `unlockAt <= now`; the decrypted plaintext is never persisted in SwiftData attributes.
5. **Fail-closed crypto gate** — SacredEchoCipher generates a Keychain-stored seed on first launch; no deterministic fallback in production.

---

## Multi-agent review process

The codebase has been reviewed three times by independent LLM agents (Grok, Claude Code, Nemotron 3 Ultra). All findings were applied; see [`.research/ORGANIZED_STATUS_NOTES_TASKS.md`](./.research/ORGANIZED_STATUS_NOTES_TASKS.md) for the full review trail. 30+ distinct issues caught and fixed; the most important was a duplicate-property compile error in `LifeGraph.swift` that would have blocked the first device build.

Every CLI dispatch prepends `.research/NO_TRAINING_PROMPT.md` to enforce no-training privacy across all model providers.

---

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md). The TL;DR: this is a privacy-first codebase. Any change that touches user data must preserve the five privacy gates. Any change to a public type listed in `OneWeaveAPI.swift` is a breaking change unless the `apiVersion` is bumped.

---

## License

MIT. See [`LICENSE`](./LICENSE).