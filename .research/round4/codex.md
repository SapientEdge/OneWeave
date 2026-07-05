OpenAI Codex v0.142.3
--------
workdir: /root/hermes-workspace/projects/oneweave
model: gpt-5.5
provider: openai
approval: never
sandbox: read-only
reasoning effort: none
reasoning summaries: none
session id: 019f0c75-da27-7063-a454-433deb2b7208
--------
user
You are Codex (GPT-5, code-focused). Specialization: FEATURE COMPLETENESS + iOS PLATFORM INTEGRATION.

PROJECT: /root/hermes-workspace/projects/oneweave (Swift 5.9/SwiftUI/SwiftData, iOS 17+). Privacy-first Life OS app. 56 Swift files, 15,710 LOC.

YOUR FOCUS:
- **Missing iOS platform integrations**: what standard iOS 17+ features should a Life OS have?
- **App Intents**: Siri/Shortcuts surface for core actions (log reflection, complete quest, check harmony, open Sacred Echo)
- **Widgets**: what widget kinds make sense? (Lock Screen, Home Screen, Live Activities)
- **Live Activities**: which long-running events should surface on Lock Screen/Dynamic Island?
- **App Shortcuts**: discovery phrases
- **Focus modes**: how should OneWeave participate?
- **Spotlight integration**: index reflections, quests, insights
- **iCloud / CloudKit**: opt-in sync (privacy-first means NO cloud by default, but opt-in for paid tier?)
- **Watch app**: what's the v1.2+ Watch face value?
- **Share extensions**: share INTO OneWeave from Safari/Mail/Photos
- **Core Spotlight, NSUserActivity, Handoff**
- **Accessibility deep-dive**: VoiceOver labels, custom rotors, Voice Control grammar, Switch Control
- **Localization**: even v1 should be en + ar (user is bilingual)?

READ:
- /root/hermes-workspace/projects/oneweave/ONEWEAVE_HANDOFF_2026-06-27.md
- /root/hermes-workspace/projects/oneweave/.specify/constitution.md
- /root/hermes-workspace/projects/oneweave/Sources/OneWeave/OneWeaveWidgetStubs.swift:222 (existing widget stubs)

OUTPUT (numbered, max 1500 words):
A. Top 10 MISSING iOS 17+ PLATFORM FEATURES
B. Top 8 APP INTENTS to implement (with full Intent struct sketch)
C. Top 5 WIDGETS to implement beyond the existing stubs (Lock Screen + Live Activity specifics)
D. Top 5 LIVE ACTIVITIES (Sacred Echo countdown, Cognitive Load trend, Season transition, etc.)
E. Top 5 ACCESSIBILITY deep-dive improvements (custom rotor for reflection gate, VoiceOver hints, etc.)
F. Localization matrix (en + ar for v1?)
G. Privacy-preserving opt-in CloudKit sync design (defer to v1.1?)

For each feature: complexity (S/M/L), Mac effort estimate, privacy implications. Be a platform engineer.

warning: Codex could not find bubblewrap on PATH. Install bubblewrap with your OS package manager. See the sandbox prerequisites: https://developers.openai.com/codex/concepts/sandboxing#prerequisites. Codex will use the bundled bubblewrap in the meantime.
codex
I’ll inspect the requested docs and the existing widget stubs first, then ground the platform recommendations in the project’s actual architecture and privacy rules. Because this is a codebase question and the repo has graphify instructions, I’ll query the graph before reading source.
exec
/bin/bash -lc "test -f graphify-out/wiki/index.md && sed -n '1,220p' graphify-out/wiki/index.md || true" in /root/hermes-workspace/projects/oneweave
 succeeded in 0ms:
exec
/bin/bash -lc "sed -n '1,260p' ONEWEAVE_HANDOFF_2026-06-27.md" in /root/hermes-workspace/projects/oneweave
 succeeded in 0ms:
# OneWeave — Master Handoff Record (2026-06-27)

**Author**: Hermes session with D S (Telegram DM)
**Date anchor**: 2026-06-27 (Saturday)
**Project location**: `/root/hermes-workspace/projects/oneweave/`
**Git branch**: `002-gamification`
**Latest commit**: `bd0972c` (chore: capture final round-3 claude re-dispatch)
**Previous milestone**: `9245b03` (fix: Claude Code review applied — 7 high-priority fixes)

---

## 🎯 TL;DR (read this first if you're picking this up cold)

OneWeave is a **privacy-first Life OS** iOS app (Swift 5.9, SwiftUI, SwiftData, iOS 17+). Built over 3-4 days on a Linux VPS by **D S + Hermes + multi-agent CLI squad** (Grok, Claude Code, Nemotron 3 Ultra). The Linux side has reached a **stable checkpoint**: algorithms, policies, privacy invariants, and validation harnesses are all in place. The project is **ready to push to GitHub and hand off to a Mac + Xcode + Claude cowork** for the device-side work.

**Headline numbers**:
- **49 Swift files**, ~15,700 lines
- **16/16 Python validation suites PASS, 525+ tests green**
- **46 Nemotron findings + 33 Claude findings** integrated into Spec Kit tasks
- **7 HIGH/blocker bugs fixed** in commit `9245b03` (reflections gates, compile errors)
- **Spec Kit adopted** (constitution v2.0 + spec 003 unified production spec)
- **Graphify knowledge graph**: 2591 nodes, 4298 edges, 179 communities
- **Aider configured** with conventions for per-feature commit workflow

---

## 📚 Where Everything Lives

### Top-level docs (read in this order)

| File | What it is | Size |
|---|---|---|
| `README.md` | Project overview, features, build status | ~4 KB |
| `ARCHITECTURE.md` | High-level architecture diagram + module map | ~8 KB |
| `MANIFEST.md` | All 49 Swift files with LOC + summary | ~12 KB |
| `FEATURE_CATALOG.md` | 23 features with file/LOC/tests/status | ~14 KB |
| `MARKETING.md` | App Store copy (30s/60s/full) + competitor table | ~10 KB |
| `PRIVACY.md` | Privacy policy + invariants | ~6 KB |
| `ONEWEAVE_HANDOFF_2026-06-27.md` | **THIS FILE** | — |
| `FIRST_WEEK_ON_MAC.md` | 7-day human checklist for Mac onboarding | ~9 KB |
| `CLAUDE_COWORK_BRIEF.md` | 30-min Mac onboarding brief for Claude cowork | ~10 KB |
| `PUSH_INSTRUCTIONS.md` | GitHub push instructions (awaiting remote URL) | ~3 KB |
| `CONVENTIONS.md` | Swift style + commit scopes + privacy invariant checks | ~4 KB |

### Spec Kit (formal production spec)

- **`.specify/constitution.md`** — v2.0, the 10 architectural principles (privacy-first, local-only, calm design, reflection-gated, anti-addictive gamification, fail-closed crypto, schema versioning, no-training, toolchain mandates, portable data)
- **`.specify/specs/003-production-readiness/`** — canonical production spec:
  - `spec.md` (24.8 KB) — 12 user stories with independent tests + edge cases + NFRs
  - `checklist.md` (5.1 KB) — CHK001-CHK063 quality gate
  - `plan.md` (12.0 KB) — TD-1 to TD-10 architectural decisions + Mac-side phases
  - `tasks.md` (11.1 KB) — Phase 0/M1-M6/V1/G1/A1/R1/P1 with T001-T074

### Research artifacts (`.research/`)

- **`build_log.md`** (881 lines) — chronological record of every cycle since project start
- **`REVIEW_ROUND_3_NEMOTRON.md`** (44.6 KB, 312 lines) — 46 findings, 14 HIGH/blockers, score 58/100
- **`REVIEW_ROUND_3_CLAUDE.md`** (13.4 KB, 118 lines) — 33 findings, 5/5 top-claims verified
- **`MARKET_RESEARCH_ROUND_3.md`** (12.5 KB) — Day One / Reflectly / Stoic / Apple Journal / Bear 2026 competitive analysis
- **`MARKET_RESEARCH_ROUND_2.md`** (10.6 KB) — 14 pain points, 8 recommendations, 5 anti-patterns
- **`ONEWEAVE_ENHANCEMENT_PLAN.md`** (5.3 KB) — enhancement roadmap
- **`ORGANIZED_STATUS_NOTES_TASKS.md`** (9.8 KB) — full status, memory/skills audit, prioritized next actions
- **`DEEPER_P2P_EXTERNAL_INTEGRATIONS_PLAN.md`** (2.5 KB)
- **`TIER_B_PLAYBOOK.md`** (13.4 KB) — 8 phases, 12-item test checklist, 8 deferred review items ranked
- **`NO_TRAINING_PROMPT.md`** — privacy prefix for all CLI dispatches
- **`AGENT_SQUAD_PROMPTS.md`** — specialized prompts per role
- **`validate_*.py`** — 16 Python validation suites (the Linux substitute for `xcodebuild`)

### Knowledge graph

- **`graphify-out/graph.json`** — 2591 nodes, 4298 edges, 179 communities (AST-extracted, no LLM cost)
- **`graphify-out/WIKI_AGENT.md`** (10.4 KB) — condensed agent-facing wiki with top 30 god nodes
- **`graphify-out/GRAPH_REPORT.md`** — full graph report

### Marketing assets

- **`landing.html`** (847 lines) — interactive landing page with SVG Compass/Loom/Echo
- **`visuals_compass.png`** (126 KB), **`visuals_loom.png`** (74 KB), **`visuals_echo.png`** (262 KB) — App Store ready PNGs
- **`MARKETING_DIAGRAMS.txt`** — ASCII versions of all diagrams

### Tooling config

- **`.aider.conf.yml`** — Aider config (model=sonnet, conventions, per-feature commit)
- **`AGENTS.md`** — auto-generated by Graphify (project-aware agent instructions)
- **`.github/agents/`** and **`.github/prompts/`** — Spec Kit agent/prompt files
- **`.specify/`** — Spec Kit constitution + specs
- **`.gitignore`** — keeps build artifacts out, tracks research + graph for agent context

---

## 🧬 What the App Does (features list — 23 total)

### Core life-graph & privacy

1. **Life Graph Engine** — typed entities/relationships/insights/patterns with privacy tiers
2. **Privacy Data Leash** — per-category toggles (Calendar/Contacts/Health/Reminders/Mail/Notes/P2P/Body Thread) checked BEFORE every integration access
3. **Invisible Mentor** — local deterministic synthesizer, only uses `isUserReflection==true` content
4. **Contradiction Weaver** — detects cross-domain contradictions, reflection-gated awards
5. **Living Graph Loom** — SwiftUI Canvas breathing renderer, polar layout

### Reflection-gated gamification (Spec Kit 002 compliant)

6. **Quest System** — quests completed via reflection-gated commits (3 essence empty / 10 essence with reflection)
7. **Season Changer** — season transitions with reflection-gated +20 burst
8. **Mastery Map** — 5 tiers (novice → luminary), per-thread
9. **Harmony Score** — 0-1, resonance threshold 0.7
10. **Essence Ledger** — append-only log of awards (20-entry cap)

### P2P / Sharing

11. **Network P2P** — Network.framework (BLE/Wi-Fi Aware) with offline queue
12. **Family Pod** — ≤6 members, quiet hours, cooldown, privacy defaults, reflection-gated receive
13. **Portable Export** — Markdown/OPML/JSON export with 3 privacy leashes
14. **Sacred Echo Vault** — AES-256-GCM + HKDF, fail-closed Keychain (post-cycle27 fix), vault seed throws on missing entry

### iOS integrations (all Data-Leash gated)

15. **Calendar/EventKit** — typed safe bindings
16. **HealthKit** — HRV baseline, sleep fragmentation, RHR via Body Thread
17. **Contacts** — typed safe bindings
18. **Reminders** — typed safe bindings
19. **Mail** — MFMailComposeViewController wrapper
20. **Notes** — UniformTypeIdentifiers integration

### Cognitive / decision support

21. **Resonance Oracle** — local decision simulator, `@MainActor` commitWeave
22. **Cognitive Load + Weave Pause** — normalized 0-1 load score, gate at 0.85 + rising trend
23. **Morning/Evening Briefings** — generated from LifeContext, weather mocked, echo countdowns, cognitive alerts
24. **Relationship Decay Tracker** — cadence-based decay, severity buckets
25. **Decision Log** — decisions with reasoning + outcome + `mentorSeeds()`
26. **Quick Capture Inbox** — 5-way classifier (task/event/journal/decision/note)

### Foundation

- **Universal Command Palette** — service-routed, reflection-gated
- **App Lifecycle Coordinator** — encrypted envelope persistence, scenePhase routing
- **Schema Migration Plan** — V1↔V3, version hashing, rollback
- **OneWeaveAPI** — public API catalog

---

## 🐛 Bugs Found & Fixed (post-cycle27)

| ID | Severity | File | Fix |
|---|---|---|---|
| CLAUDE-R3-1 | HIGH/blocker | LifeContext.swift:440 | `completeQuest` reflection gate: 3 vs 10 essence |
| CLAUDE-R3-2 | HIGH/blocker | LifeContext.swift:108 | `changeSeason` gates +20 burst behind `seasonReflectionCompleted` |
| CLAUDE-R3-3 | HIGH/blocker | GraphInsightGenerator.swift:344 | `.balanced` → `.normal` (compile error fix) |
| CLAUDE-R3-7 | HIGH/blocker | BodyThreadWeaver.swift:51 | `attributes: String` → `attributes["bodyMetrics"]` |
| CLAUDE-R3-22 | HIGH/blocker | PortableExport.swift | `kind` → `type`, `fromEntityID` → optional unwrap |
| CLAUDE-R3-23 | HIGH/blocker | CognitiveLoad.swift | Removed `objc_*AssociatedObject` extension |
| NEMO-R3-018 | HIGH/blocker | SacredEcho.swift | `vaultSeed()` now throws (fail-closed Keychain) |
| NEMO-R3-020/042 | HIGH/blocker | CompassView.swift | `@AppStorage("hasCompletedOnboarding")` for persistent onboarding |

**All 8 fixes verified by independent grep against source.** No hallucinated findings.

---

## 🔴 Known Gaps (require Mac + Xcode)

These cannot be done on Linux. They are the Mac coworker's first priority:

### Nemotron HIGH/blockers (14 total)

- **NEMO-R3-001** — Info.plist missing (app crashes on first HealthKit/Calendar/Contacts access)
- **NEMO-R3-002** — App Group `group.com.oneweave` not provisioned
- **NEMO-R3-010** — Xcode project doesn't exist
- **NEMO-R3-011** — Snapshot key `"oneweave.snapshot.v1"` not bundle-ID scoped
- **NEMO-R3-012** — Widget Extension target missing
- **NEMO-R3-013** — AppShortcutsProvider missing (Siri won't surface AppIntents)
- **NEMO-R3-014** — Apple Developer account setup unclear
- **NEMO-R3-015/016/017** — Sacred Echo reviewer-facing artifacts (Decree/Heir) + appeal path
- **NEMO-R3-023** — V1→V3 migration has `String → [String:String]` type change requiring custom migration
- **NEMO-R3-024** — No migration rollback path
- **NEMO-R3-031** — PrivacyPolicy.md underspecified for App Review

### Claude Code HIGH/blockers (deferred)

- **CLAUDE-R3-18/19/20** — FamilyPod builder uses 3 non-existent `LifeContext` members + mutates `let` fields + wrong `.title` vs `.name` — needs API surface additions:
  - `var threads: [BasicSelfThread]`
  - `var currentSeasonName: String` (computed)
  - `var activeAmplifierName: String?` (computed)
  - Change `FamilyPodDigestEntry` fields from `let` to `var`

### Claude MEDIUM (12+)

- Privacy: thread-names opt-in (R3-21), reflection plaintext in ledger (R3-28), private entity in P2P insight (R3-4)
- Crypto: HKDF salt from public echoID prefix (R3-9), seed: param not #if DEBUG (R3-10), single envelope key (R3-14)
- Correctness: `LifeRelationship` no `deleteRule` (R3-6), loom 15fps recompute (R3-33), CommandPalette pendingAction never committed (R3-27)

---

## 🎬 Next Steps (in priority order)

### On Linux (still possible here)

1. **Apply remaining 12 Linux-fixable Nemotron findings** (schema migration V2 stage, widget atomic snapshot, widget refresh policy, widget placeholder, PRIVACY.md category names, Body Thread privacy gate, reflection min length, onboarding persistence, DEBUG guards)
2. **Build the tarball** for offline transfer: `cd /root/hermes-workspace && tar czf oneweave-linux-handoff-2026-06-27.tar.gz projects/oneweave --exclude='.git'`
3. **Update tasks.md** with T075-T120+ for all Nemotron/Claude findings (already covered in spec 003)

### GitHub push (waiting on user)

- Need the GitHub remote URL + auth choice (SSH key vs HTTPS token vs `gh` CLI login)
- `PUSH_INSTRUCTIONS.md` has the full path

### On Mac (post-push)

- Week 1: `FIRST_WEEK_ON_MAC.md` checklist (xcodebuild first to catch compile-blockers as a batch)
- Run Claude cowork with `CLAUDE_COWORK_BRIEF.md` as initial context
- Address Nemotron + Claude HIGH/blockers in priority order
- TestFlight → App Store submission

---

## 🧠 Key Architectural Decisions (carry-forward)

1. **Privacy-first** — local-only data storage, no external APIs/keys, no LLM/Core ML/network in core
2. **Reflection-gated** — every state-changing action requires non-empty reflection text (principle 2 in constitution)
3. **Fail-closed crypto** — `vaultSeed()` throws on missing Keychain entry; no test fallback in production paths
4. **isUserReflection gate** — `InvisibleMentor` only synthesizes from user-authored reflections
5. **Data Leash before everything** — `currentLeash(in:)` precedes every integration access
6. **Life Graph as foundation** — Tier 1 priority, types-as-privacy-tiers
7. **App lifecycle uses encrypted envelope** — SacredEcho vault seed via HKDF for LifeGraph JSON persistence
8. **App Group** — `group.com.oneweave` for widget data sharing
9. **Seasons** — spring/summer/autumn/winter with bonuses/gates/bursts
10. **Mastery tiers** — 5 levels (novice → luminary), per-thread

---

## ⚠️ Known Process Gaps (learned this session)

1. **Linux validation green ≠ Swift compiles.** Python mirrors validate algorithms/policies but cannot validate Swift type-system invariants. The Mac coworker's first action MUST be `xcodebuild` to surface all compile-blockers as a batch.
2. **CLI agent reviews need PTY mode** — Grok/Claude Code return stubs without it; non-interactive dispatchers can't answer permission gates.
3. **"Production ready" should always distinguish** "Linux algorithms validated" from "Swift compiles" from "App Store approved" — these are very different bars.
4. **Spec Kit + Graphify + Aider adoption took 4 days** — should have been on from day 1.

---

## 📞 Re-establishing context after sessions reset

Future-Hermes-session will need:
1. **This file** (`ONEWEAVE_HANDOFF_2026-06-27.md`) as the entry point
2. **Spec Kit** (`specify` CLI is installed) for plan-driven work
3. **Graphify** (`graphify` CLI is installed) for codebase understanding
4. **Aider** (`.aider.conf.yml` configured) for commit-discipline implementation
5. **16 validation suites** for Linux-side regression checks
6. **`session_search`** to recall past conversations: `session_search(query="OneWeave", limit=5)`

The skill `linux-vetted-apple-handoff` is the canonical workflow for this kind of Linux-builds-iOS-then-hands-off-to-Mac project.

---

**End of master handoff. The work is on disk, committed, validated, and documented. Safe to reset sessions.**

exec
/bin/bash -lc "sed -n '1,260p' .specify/constitution.md" in /root/hermes-workspace/projects/oneweave
 succeeded in 0ms:
# OneWeave Constitution

**Version:** 2.0 — Updated 2026-06-27 after Spec Kit + Graphify + Aider toolchain adoption.

This constitution governs ALL OneWeave work. Every spec, plan, task, and implementation must comply.

---

## Core Principles

### 1. One Journey, Not Silos
Life is interconnected. OneWeave models and surfaces real relationships between domains (health affects energy for goals, goals affect relationships and finances, etc.). The four Threads (Self, Stewardship, Care & Kin, Meaning & Legacy) are fluid lenses, not rigid tabs. Interconnections are first-class citizens.

### 2. Privacy-First, Zero-Trust
- All data stays on the user's device by default. Zero accounts. Zero cloud sync on free tier.
- Sacred Echo Vault uses **AES-256-GCM + HKDF-SHA256** with fail-closed crypto (no test seed fallback; deterministic nonce fallback removed).
- Provider opt-outs are mandatory for any LLM/agent dispatch (`/root/.hermes/scripts/oneweave_dispatch.sh` prepends `.research/NO_TRAINING_PROMPT.md`).
- Redact PII/secrets before any external dispatch.
- **Privacy Data Leash**: 9 integration toggles (Calendar, Contacts, HealthKit, Reminders, Mail, Notes, Body Thread, P2P, Insights). Each gated individually. Each read live from `DataLeashSettingsRecord` BEFORE any data access.

### 3. Calm Intelligence
- On-device AI used sparingly and transparently to amplify human wisdom, reduce load, and foster real-world actions (IRL connections, analog time).
- **No Core ML, no LLM, no network** in core features (Invisible Mentor, Quick Capture, Cognitive Load, all synthesis). Pure algorithmic + user's own data.
- No streak shaming. No bouncy animations. No "🎉". Spring animations are `.spring(response: 0.4, dampingFraction: 0.7)`. Soft and slow.

### 4. Reflection-Gated Everything
Any action that produces lasting consequence (saving an insight, completing a quest, sharing via P2P, sealing a Sacred Echo, committing via Command Palette, applying a Cross-Domain Insight) requires a **non-empty `reflectionText`** from the user. This is the moral core of the app — pause before you commit.

### 5. Anti-Addictive Gamification
- Streaks have **restorative grace** (max 2 days) and gentle decay (0.5%/day after 7-day grace). No "you lost your streak!" notifications.
- Weave Pause triggers ONLY when cognitive load is rising AND ≥ 0.85 AND body depleted (NOT on sustained high — verified by `validate_cognitive_load.py`).
- Mastery tiers (novice → adept → expert → master → grandmaster) require genuine mastery, not time-served.

### 6. Genuine Help Over Features
Solve real 2026 needs: fragmentation, loneliness, caregiver burden, digital fatigue, meaning deficit. High retention through compounding value, not gamification or addiction. Every feature must answer: "Does this honor what actually matters to the user?"

### 7. Plan Rigorously, Build Real
- Use Spec Kit (this directory) for every new feature branch.
- Run Graphify on the codebase before heavy changes (`graphify . --update --wiki`).
- Validate in Python mirrors before Mac compilation (Linux has no swiftc).
- Deliver working artifacts. No stubs in production paths. No "TODO: implement later."
- Talk/plan before code. Conversational first; act only on explicit approval.

---

## Non-Goals

- Another bloated all-in-one or Notion clone.
- Heavy social/gamified features that increase screen time.
- Medical/financial advice replacement.
- Public data sharing without explicit consent (defaults are `private`).
- Cross-device sync on free tier (paid tier uses user's own iCloud Drive).
- Apple Health predictions or diagnosis (we surface signals, not conclusions).

---

## Architectural Invariants

These MUST NOT change without explicit user approval and a constitution amendment:

1. **App Group identifier**: `group.com.oneweave` (shared with WidgetKit extension)
2. **Widget snapshot key**: `oneweave.snapshot.v1`
3. **SwiftData schema versioning**: V1 → V2 → V3 with explicit migration logic in `SchemaMigrationPlan.swift`
4. **Sacred Echo crypto**: AES-256-GCM + HKDF-SHA256, fail-closed, no plaintext reflections stored
5. **Reflection gate**: required on every state-changing action
6. **Privacy tier**: every `LifeEntity` has `private` / `shared` / `public`; default `private`
7. **Data Leash**: 9 toggles, read live BEFORE integration call, fail-closed (deny if missing)
8. **P2P encryption**: Signal Protocol via libsignal-client; STUN stun.l.google.com:19302; TURN self-hosted Coturn
9. **iOS minimum**: iOS 17+ (SwiftData requirement)
10. **Color convention** (for consistency across all views): Self=.blue, Stewardship=.green, CareKin=.orange, Meaning=.purple

---

## Success Metrics

### User-facing
- User feels reduced fragmentation and better trade-off decisions.
- Daily/weekly use becomes natural because it saves time/energy.
- High willingness-to-pay via premium subscription ($9.99/mo or $79.99/yr).
- Privacy maintained; zero training leakage incidents.
- Sacred Echo Vault users report the feature "changed how I think about legacy."

### Engineering-facing
- All features validated end-to-end in Python mirrors on Linux before Mac compilation.
- Real bugs caught by validators before they reach users (target: 100%).
- Codex Aider per-feature commits; one branch per spec; clean git history.
- Zero external API dependencies in production paths.

---

## Toolchain (mandated)

| Purpose | Tool | Location |
|---|---|---|
| Specification | Spec Kit (`specify` CLI) | `.specify/` |
| Codebase context | Graphify (`graphify` CLI) | `graphify-out/` |
| Implementation | Aider (per-feature commits) | `.aider.conf.yml` |
| Validation | Python mirrors | `.research/validate_*.py` |
| Dispatch | `oneweave_dispatch.sh` | `/root/.hermes/scripts/` |
| Build log | `.research/build_log.md` | per-spec append |

**Every new feature requires all five artifacts:**
1. `.specify/specs/<NNN-feature>/spec.md` + `tasks.md` + `checklist.md` + `plan.md` + `analysis.md`
2. `graphify . --update` after implementation
3. Aider commit per task (no bundling)
4. Python mirror tests in `.research/validate_<feature>.py`, all passing
5. Entry in `.research/build_log.md` with timestamp + LOC + tests + bugs caught

---

## Constitutional Amendments

Amendments require explicit user approval and update this file with version bump.

- v1.0 (2026-06-24): Initial constitution.
- v2.0 (2026-06-27): Added toolchain mandates, architectural invariants, reflection-gated principle, anti-addictive gamification details. Reflects post-Tier A/Round 2/Linux push reality.

---

*This constitution governs all OneWeave work and inherits global Hermes best practices.*
exec
/bin/bash -lc "nl -ba Sources/OneWeave/OneWeaveWidgetStubs.swift | sed -n '1,360p'" in /root/hermes-workspace/projects/oneweave
 succeeded in 0ms:
     1	// OneWeaveWidgetStubs.swift
     2	// Phase 8 production: Harmony/Quest widgets production + App Intents + Live Activities
     3	// Concrete per tasks.md Phase 8: 
     4	// - Harmony Widget (small/medium via WidgetKit): TimelineProvider pulls harmonyScore, top active/suggested quest from LifeContext/@Query; mini 4-thread tapestry preview + "Open OneWeave". 
     5	// - Medium: 1-2 quest list with domain tags + "Accept" AppIntent deep link. 
     6	// - Live Activity: Active quest "IRL: 15min • +baseEssence on reflect" or streak counter with grace state. Uses ActivityKit + local push updates.
     7	// - Siri/App Intents: "Show my harmony", "Weave quick capture <text> for <thread>", "Complete current quest with reflection <note>" (donate shortcuts). 
     8	// Shared snapshot provider (OneWeaveSnapshot) e.g. export simple struct from LifeContext for widget target. 
     9	// Post production; requires Xcode target setup for WidgetExtension (App Group for sharing snapshot JSON/UserDefaults).
    10	// All local-only SwiftData queries via snapshot (no direct @Model in ext). Harmony/quest focus per Phase 8 + DESIGN peripheral hooks.
    11	// Production scope complete. Ready for Xcode target.
    12	
    13	import Foundation
    14	import SwiftUI
    15	import WidgetKit
    16	import AppIntents
    17	
    18	// Example shared snapshot for widget data parity (export from LifeContext in main app)
    19	
    20	
    21	// MARK: - Harmony Widget (small/medium)
    22	struct HarmonyWidgetProvider: TimelineProvider {
    23	    typealias Entry = HarmonyEntry
    24	    
    25	    func placeholder(in context: Context) -> HarmonyEntry {
    26	        HarmonyEntry(date: Date(), snapshot: OneWeaveSnapshotStore.shared.read())
    27	    }
    28	    
    29	    func getSnapshot(in context: Context, completion: @escaping (HarmonyEntry) -> ()) {
    30	        // In real: load from app group shared UserDefaults or JSON snapshot written by main app
    31	        let snap = OneWeaveSnapshotStore.shared.read()
    32	        completion(HarmonyEntry(date: Date(), snapshot: snap))
    33	    }
    34	    
    35	    func getTimeline(in context: Context, completion: @escaping (Timeline<HarmonyEntry>) -> ()) {
    36	        let snap = OneWeaveSnapshotStore.shared.read()
    37	        let entry = HarmonyEntry(date: Date(), snapshot: snap)
    38	        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15*60))) // refresh 15min
    39	        completion(timeline)
    40	    }
    41	}
    42	
    43	struct HarmonyEntry: TimelineEntry {
    44	    let date: Date
    45	    let snapshot: OneWeaveSnapshot
    46	}
    47	
    48	struct HarmonyWidget: Widget {
    49	    let kind: String = "OneWeaveHarmonyWidget"
    50	    
    51	    var body: some WidgetConfiguration {
    52	        StaticConfiguration(kind: kind, provider: HarmonyWidgetProvider()) { entry in
    53	            HarmonyWidgetView(entry: entry)
    54	        }
    55	        .configurationDisplayName("OneWeave Harmony")
    56	        .description("Current harmony and top quest at a glance.")
    57	        .supportedFamilies([.systemSmall, .systemMedium])
    58	    }
    59	}
    60	
    61	struct HarmonyWidgetView: View {
    62	    var entry: HarmonyEntry
    63	    var body: some View {
    64	        VStack(alignment: .leading, spacing: 4) {
    65	            Text("Harmony \(Int(entry.snapshot.harmonyScore * 100))%")
    66	                .font(.headline)
    67	            Text("L\(entry.snapshot.weaveLevel) • 🔥\(entry.snapshot.globalWeaveStreak) (grace \(entry.snapshot.graceDaysUsed))")
    68	                .font(.caption)
    69	            if let q = entry.snapshot.topQuestTitle {
    70	                Text("Quest: \(q)")
    71	                    .font(.caption2)
    72	                    .foregroundStyle(.secondary)
    73	                    .lineLimit(1)
    74	            }
    75	            // Mini tapestry preview production
    76	            HStack(spacing: 2) {
    77	                ForEach(["Self","Stewardship","CareKin","Meaning"], id: \.self) { d in
    78	                    Circle().fill(Color.blue.opacity(0.6)).frame(width: 6, height: 6)
    79	                }
    80	            }
    81	        }
    82	        .padding(8)
    83	    }
    84	}
    85	
    86	// MARK: - Quest Widget production (medium family, per Phase 8 concrete)
    87	struct QuestWidgetProvider: TimelineProvider {
    88	    typealias Entry = QuestEntry
    89	    
    90	    func production(in context: Context) -> QuestEntry {
    91	        QuestEntry(date: Date(), quests: [
    92	            OneWeaveQuestStub(title: "3-day body awareness", domain: "Self", estMinutes: 15, essence: 8),
    93	            OneWeaveQuestStub(title: "Log 1 CareKin interaction", domain: "CareKin", estMinutes: 20, essence: 12)
    94	        ])
    95	    }
    96	    
    97	    func getSnapshot(in context: Context, completion: @escaping (QuestEntry) -> ()) {
    98	        let q = OneWeaveQuestStub(title: "Reflect on legacy story", domain: "Meaning", estMinutes: 10, essence: 15)
    99	        completion(QuestEntry(date: Date(), quests: [q]))
   100	    }
   101	    
   102	    func getTimeline(in context: Context, completion: @escaping (Timeline<QuestEntry>) -> ()) {
   103	        let quests = [
   104	            OneWeaveQuestStub(title: "Audit 1 subscription leak", domain: "Stewardship", estMinutes: 5, essence: 6),
   105	            OneWeaveQuestStub(title: "Schedule non-digital meetup", domain: "CareKin", estMinutes: 30, essence: 10)
   106	        ]
   107	        let entry = QuestEntry(date: Date(), quests: quests)
   108	        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30*60)))
   109	        completion(timeline)
   110	    }
   111	}
   112	
   113	struct OneWeaveQuestStub: Identifiable, Codable {
   114	    let id = UUID()
   115	    let title: String
   116	    let domain: String
   117	    let estMinutes: Int
   118	    let essence: Int
   119	}
   120	
   121	struct QuestEntry: TimelineEntry {
   122	    let date: Date
   123	    let quests: [OneWeaveQuestStub]
   124	}
   125	
   126	struct QuestWidget: Widget {
   127	    let kind: String = "OneWeaveQuestWidget"
   128	    
   129	    var body: some WidgetConfiguration {
   130	        StaticConfiguration(kind: kind, provider: QuestWidgetProvider()) { entry in
   131	            QuestWidgetView(entry: entry)
   132	        }
   133	        .configurationDisplayName("OneWeave Quests")
   134	        .description("Top suggested quests. Tap to accept (via AppIntent).")
   135	        .supportedFamilies([.systemMedium])
   136	    }
   137	}
   138	
   139	struct QuestWidgetView: View {
   140	    var entry: QuestEntry
   141	    var body: some View {
   142	        VStack(alignment: .leading, spacing: 6) {
   143	            Text("Suggested Weaves").font(.headline)
   144	            ForEach(entry.quests.prefix(2)) { q in
   145	                HStack {
   146	                    Text("• \(q.domain): \(q.title)")
   147	                        .font(.caption)
   148	                        .lineLimit(1)
   149	                    Spacer()
   150	                    Text("+\(q.essence)✧ \(q.estMinutes)m")
   151	                        .font(.caption2)
   152	                        .foregroundStyle(.secondary)
   153	                }
   154	            }
   155	            Text("Accept via app or Siri").font(.caption2).foregroundStyle(.tertiary)
   156	        }
   157	        .padding(8)
   158	    }
   159	}
   160	
   161	// MARK: - App Intents for Siri/Shortcuts
   162	struct LogWeaveIntent: AppIntent {
   163	    static var title: LocalizedStringResource = "Log a Weave"
   164	    static var description = IntentDescription("Quick weave capture into OneWeave threads.")
   165	    
   166	    @Parameter(title: "Text") var text: String
   167	    @Parameter(title: "Thread") var thread: String?
   168	    
   169	    func perform() async throws -> some IntentResult {
   170	        // In real: call via URL scheme or shared store to main app to emit TimelineEvent
   171	        return .result()
   172	    }
   173	}
   174	
   175	struct CompleteQuestIntent: AppIntent {
   176	    static var title: LocalizedStringResource = "Complete Quest with Reflection"
   177	    @Parameter(title: "Reflection Note") var note: String
   178	    
   179	    func perform() async throws -> some IntentResult {
   180	        // Requires reflection note for full award
   181	        return .result()
   182	    }
   183	}
   184	
   185	struct ShowHarmonyIntent: AppIntent {
   186	    static var title: LocalizedStringResource = "Show My OneWeave Harmony"
   187	    func perform() async throws -> some IntentResult { /* deep link or queue in real */ return .result() }
   188	}
   189	
   190	// MARK: - Live Activity production (for active quest or streak)
   191	struct OneWeaveLiveActivityAttributes: ActivityAttributes {
   192	    public struct ContentState: Codable, Hashable {
   193	        var questTitle: String
   194	        var irlMinutesLeft: Int
   195	        var currentEssence: Int
   196	        var streak: Int
   197	    }
   198	    var questId: String
   199	}
   200	
   201	// Usage: In main app: Activity<OneWeaveLiveActivityAttributes>.request(...) with initial content state from LifeContext
   202	// Widget for Live Activity UI in separate target.
   203	
   204	// Widget bundle for extension
   205	#if canImport(WidgetKit) && WIDGET_EXTENSION
   206	@main
   207	struct OneWeaveWidgets: WidgetBundle {
   208	    var body: some Widget {
   209	        HarmonyWidget()
   210	        QuestWidget()
   211	    }
   212	}
   213	
   214	// Notes:
   215	// - Add to Xcode: File > New > Target > Widget Extension; share app group with main OneWeave target for snapshot JSON.
   216	// - Privacy: All data local; widgets use on-device snapshot only.
   217	// - Harmony/quest focus per Phase 8 + DESIGN peripheral hooks. Production implementation includes full Harmony + Quest providers/views + intents + live attrs (polished per concrete).
   218	// - Update after production when core stable. See LAUNCH_CHECKLIST + tasks.md for full concrete.
   219	// - Production widget preview (Harmony + Quest) integrated in OneWeavePrototype.swift (sim UI using snapshot-like data from LifeContext for testing flows).
   220	// - For PWA parity: web equivalent via notification or home screen "widget" like add-to-home with dynamic manifest updates (future).
   221	// - production: no full target setup here (Linux env); productions + preview only.
   222	#endif

exec
/bin/bash -lc 'test -f graphify-out/graph.json && graphify query "Missing iOS platform integrations App Intents widgets Live Activities Spotlight CloudKit accessibility localization OneWeave" || true' in /root/hermes-workspace/projects/oneweave
 succeeded in 207ms:
Traversal: BFS depth=2 | Start: ['Accessibility', 'OneWeave', 'App'] | 33 nodes found

NODE Feature Specification: OneWeave Production Readiness (003) [src=.specify/specs/003-production-readiness/spec.md loc=L1 community=]
NODE README.md [src=README.md loc=L1 community=]
NODE OneWeave [src=README.md loc=L1 community=]
NODE AppStateMachine [src=Sources/OneWeave/AppStateMachine.swift loc=L48 community=]
NODE Non-Functional Requirements *(mandatory)* [src=.specify/specs/003-production-readiness/spec.md loc=L291 community=]
NODE OneWeaveApp.swift [src=Sources/OneWeave/OneWeaveApp.swift loc=L1 community=]
NODE CLAUDE_COWORK_BRIEF.md [src=CLAUDE_COWORK_BRIEF.md loc=L1 community=]
NODE Quick start [src=README.md loc=L43 community=]
NODE PRIVACY.md [src=PRIVACY.md loc=L1 community=]
NODE OneWeaveApp [src=Sources/OneWeave/OneWeaveApp.swift loc=L4 community=]
NODE ARCHITECTURE.md [src=ARCHITECTURE.md loc=L1 community=]
NODE TIER_B_PLAYBOOK.md [src=.research/TIER_B_PLAYBOOK.md loc=L1 community=]
NODE CONTRIBUTING.md [src=CONTRIBUTING.md loc=L1 community=]
NODE MANIFEST.md [src=MANIFEST.md loc=L1 community=]
NODE ORGANIZED_STATUS_NOTES_TASKS.md [src=.research/ORGANIZED_STATUS_NOTES_TASKS.md loc=L1 community=]
NODE FIRST_WEEK_ON_MAC.md [src=FIRST_WEEK_ON_MAC.md loc=L1 community=]
NODE root_hermes_workspace_projects_oneweave_license_md [src= loc= community=]
NODE Contributing [src=README.md loc=L108 community=]
NODE For privacy / security reviewers [src=README.md loc=L61 community=]
NODE Performance [src=.specify/specs/003-production-readiness/spec.md loc=L293 community=]
NODE Multi-agent review process [src=README.md loc=L100 community=]
NODE For Linux developers (validation only) [src=README.md loc=L52 community=]
NODE License [src=README.md loc=L114 community=]
NODE Calm Design [src=.specify/specs/003-production-readiness/spec.md loc=L320 community=]
NODE What this repo contains [src=README.md loc=L27 community=]
NODE Privacy [src=.specify/specs/003-production-readiness/spec.md loc=L302 community=]
NODE For Mac-side developers (Xcode) [src=README.md loc=L45 community=]
NODE Privacy commitments [src=README.md loc=L88 community=]
NODE Reliability [src=.specify/specs/003-production-readiness/spec.md loc=L308 community=]
NODE Accessibility [src=.specify/specs/003-production-readiness/spec.md loc=L314 community=]
NODE Architecture [src=README.md loc=L67 community=]
NODE App [src= loc= community=]
NODE Scene [src=Sources/OneWeave/OneWeaveApp.swift loc=L11 community=]
EDGE Accessibility --contains [EXTRACTED]--> Non-Functional Requirements *(mandatory)*
EDGE App --implements [EXTRACTED]--> OneWeaveApp
EDGE OneWeave --contains [EXTRACTED]--> README.md
EDGE OneWeave --contains [EXTRACTED]--> What this repo contains
EDGE OneWeave --contains [EXTRACTED]--> Quick start
EDGE OneWeave --contains [EXTRACTED]--> Architecture
EDGE OneWeave --contains [EXTRACTED]--> Privacy commitments
EDGE OneWeave --contains [EXTRACTED]--> Multi-agent review process
EDGE OneWeave --contains [EXTRACTED]--> Contributing
EDGE OneWeave --contains [EXTRACTED]--> License
EDGE OneWeaveApp --contains [EXTRACTED]--> OneWeaveApp.swift
EDGE OneWeaveApp --references [EXTRACTED context=field]--> Scene
EDGE OneWeaveApp --calls [INFERRED context=call]--> AppStateMachine
EDGE README.md --references [EXTRACTED]--> FIRST_WEEK_ON_MAC.md
EDGE README.md --references [EXTRACTED]--> CLAUDE_COWORK_BRIEF.md
EDGE README.md --references [EXTRACTED]--> TIER_B_PLAYBOOK.md
EDGE README.md --references [EXTRACTED]--> MANIFEST.md
EDGE README.md --references [EXTRACTED]--> PRIVACY.md
EDGE README.md --references [EXTRACTED]--> ARCHITECTURE.md
EDGE README.md --references [EXTRACTED]--> ORGANIZED_STATUS_NOTES_TASKS.md
EDGE README.md --references [EXTRACTED]--> CONTRIBUTING.md
EDGE README.md --references [EXTRACTED]--> root_hermes_workspace_projects_oneweave_license_md
EDGE Non-Functional Requirements *(mandatory)* --contains [EXTRACTED]--> Feature Specification: OneWeave Production Readiness (003)
EDGE Non-Functional Requirements *(mandatory)* --contains [EXTRACTED]--> Performance
EDGE Non-Functional Requirements *(mandatory)* --contains [EXTRACTED]--> Privacy
EDGE Non-Functional Requirements *(mandatory)* --contains [EXTRACTED]--> Reliability
EDGE Non-Functional Requirements *(mandatory)* --contains [EXTRACTED]--> Calm Design
EDGE Quick start --contains [EXTRACTED]--> For Mac-side developers (Xcode)
EDGE Quick start --contains [EXTRACTED]--> For Linux developers (validation only)
EDGE Quick start --contains [EXTRACTED]--> For privacy / security reviewers

codex
The requested files confirm the main constraints: local-only by default, App Group `group.com.oneweave`, widget snapshot key `oneweave.snapshot.v1`, reflection gates for durable actions, and existing widget work is still stub-level around Harmony, Quest, three intents, and one Live Activity attributes type. I’m doing one quick symbol pass now so the recommendations map to real feature names rather than generic iOS checklists.
exec
/bin/bash -lc "sed -n '1,220p' ARCHITECTURE.md" in /root/hermes-workspace/projects/oneweave
 succeeded in 0ms:
# OneWeave Architecture

A high-level map of the OneWeave module. Read [`MANIFEST.md`](./MANIFEST.md) for per-file details and [`OneWeaveAPI.swift`](./Sources/OneWeave/OneWeaveAPI.swift) for the public API catalog.

## Layered structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          OneWeaveApp (entry)                            │
│  • SwiftData ModelContainer (11 @Model types)                          │
│  • @Environment(\.scenePhase) → AppLifecycleCoordinator                │
└─────────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────────┐
        │                         │                             │
┌───────▼──────────┐    ┌─────────▼─────────┐         ┌─────────▼─────────┐
│  Core state      │    │  Creative features│         │  Privacy layer    │
│                  │    │                   │         │                   │
│ • LifeContext    │    │ • SacredEcho      │         │ • DataLeashSettings│
│ • LifeGraph      │    │ • InvisibleMentor │         │ • PrivacyTier     │
│ • TimelineEvent  │    │ • MentorEchoBridge│         │   (private/shared │
│ • WeaveQuest     │    │ • ResonanceOracle │         │    /public)       │
│ • 4 Thread types │    │ • BodyThreadWeaver│         │ • Data Leash gate │
└──────────────────┘    │ • LivingGraphLoom │         │   (BEFORE every   │
                        └───────────────────┘         │    integration)   │
                                                      └───────────────────┘
        ┌─────────────────────────┼─────────────────────────────┐
        │                         │                             │
┌───────▼──────────┐    ┌─────────▼─────────┐         ┌─────────▼─────────┐
│  Insights        │    │  P2P + Family     │         │  Export + Migrate │
│                  │    │                   │         │                   │
│ • GraphInsight   │    │ • P2PWeaveShare   │         │ • PortableExport  │
│   Generator      │    │ • FamilyPod       │         │ • SchemaMigration │
│ • @MainActor     │    │ • 5 quiet pillars │         │   Plan            │
│ • 5-min cache    │    │ • ≤6 members/cap  │         │ • 3 leashes       │
└──────────────────┘    └───────────────────┘         └───────────────────┘
```

## Data flow: write a reflection → see it reflected

```
User writes reflection
        │
        ▼
WeaveQuest.complete(reflectionText: "...")       [reflection gate #1]
        │
        ├─→ TimelineService.append(event)
        │
        ├─→ LifeContext.lifeGraphEntities.append(
        │       LifeEntity(
        │           kind: .task,
        │           summary: reflectionText,
        │           isUserReflection: true,        [consent gate #3]
        │           isPrivate: <from Data Leash>
        │       ))
        │
        ├─→ GraphInsightGenerator.invalidateCache()
        │
        └─→ OneWeaveSnapshotStore.pushSnapshot()  [widget sync]
```

## Data flow: receive a P2P share from a peer

```
Peer sends WeaveCircleShare
        │
        ▼
P2PWeaveShare.receiveAndIntegrate(...)
        │
        ├─→ Data Leash check: target category enabled?
        │       [data leash gate #2]
        │       └─→ if NO: drop silently
        │
        ├─→ if YES: hold in pendingIntegrations
        │           (NOT in lifeGraphEntities yet)
        │
        ▼
UI shows "1 pending weave, write a reflection to accept"
        │
        ▼
User writes reflection + taps Accept
        │
        ▼
P2PWeaveShare.drainPending(reflectionText: ...)
        │
        ├─→ [reflection gate #1 — empty text → nothing happens]
        │
        └─→ if non-empty: insert entities into lifeGraphEntities
                            with isUserReflection=false (it's not the user's
                            words; it's the peer's)
```

## The five privacy gates (type-level enforcement)

1. **Reflection gate** — every `commit`-shaped function takes a
   non-empty `reflectionText: String` argument. Empty → function throws
   or returns empty.
2. **Data Leash gate** — every integration path reads `DataLeashPolicy.
   currentLeash(in: modelContext)` BEFORE calling into EventKit /
   Contacts / HealthKit / etc. If the user's toggle is off, the function
   returns before any framework call.
3. **Consent gate** — `LifeEntity.isUserReflection: Bool` distinguishes
   user-authored content from system content. InvisibleMentor only
   synthesizes from `isUserReflection == true`.
4. **isUserReflection gate** — Sacred Echo plaintext is decrypted only
   when `unlockAt <= now`. Decrypted plaintext is never persisted in
   SwiftData attributes (only ciphertext + nonce + tag).
5. **Fail-closed crypto gate** — SacredEchoCipher generates a Keychain
   seed on first launch. No deterministic fallback in production code.
   The deterministic test seed is `#if !canImport(Security)` only.

## Threading model

- `@MainActor` — every UI-touching store / coordinator
  (SacredEchoStore, AppLifecycleCoordinator, GraphInsightGenerator,
  MentorEchoBridge convenience methods).
- Pure functions (no actor isolation) — renderers, validators, hashers,
  policy functions. These are unit-testable on Linux without a runtime.
- Background — P2P transport (Network framework, WebRTC) is owned by
  Apple frameworks; we do not wrap them in actors.

## Validation strategy on Linux

Because we can't run SwiftData or SwiftUI on Linux, every behavior that
doesn't depend on the Apple runtime is mirrored in Python:

- `.research/validate_tierA*.py` — Tier A features (Insight cache, iOS
  integrations, Sacred Echo, Mentor, App Lifecycle).
- `.research/validate_round2_loom.py` — Living Graph Loom.
- `.research/validate_mentor_bridge.py` — Mentor × Sacred Echo bridge.
- `.research/validate_family_pod.py` — Family Pod policy + builder.
- `.research/validate_portable_export.py` — Privacy-leash export.
- `.research/validate_schema_migration.py` — V1↔V3 attribute conversion.
- `.research/validate_stress.py` — 1k/10k entity stress harness.

Run them all: `bash .research/validate_all.sh`.

## Multi-agent review process

Three independent LLM agents have reviewed the codebase:

1. **Grok** (supergrok OAuth) — Tier A reviews + cycles 14-16.
2. **Claude Code** (opus, via PTY) — Cycles 14-16, Tier A + Round 2.
3. **Nemotron 3 Ultra** (via delegate_task) — Final review that caught
   the `LifeGraph.swift` duplicate-property compile bug.

Findings → applied → regression-tested → log appended to
`.research/build_log.md`. The process is repeatable; see
`.research/AGENT_SQUAD_PROMPTS.md` for the role-specialized prompts.

Every dispatch prepends `.research/NO_TRAINING_PROMPT.md` so all models
operate in private / no-training mode.
exec
/bin/bash -lc 'rg -n "struct .*Intent|AppShortcutsProvider|ActivityAttributes|Widget|NSUserActivity|CSSearchable|CoreSpotlight|CloudKit|Focus|Shortcut|Spotlight|Handoff|DataLeash|SacredEcho|CognitiveLoad|Quest|Season|Reflection" Sources/OneWeave .specify/specs/003-production-readiness/spec.md PRIVACY.md ARCHITECTURE.md' in /root/hermes-workspace/projects/oneweave
exec
/bin/bash -lc 'rg --files Sources/OneWeave | sort' in /root/hermes-workspace/projects/oneweave
 succeeded in 0ms:
Sources/OneWeave/AppLifecycleCoordinator.swift
Sources/OneWeave/AppStateMachine.swift
Sources/OneWeave/BasicSelfThread.swift
Sources/OneWeave/BodyThreadSheet.swift
Sources/OneWeave/BodyThreadWeaver.swift
Sources/OneWeave/CareKinThread.swift
Sources/OneWeave/CognitiveLoad.swift
Sources/OneWeave/CommandPalette.swift
Sources/OneWeave/CompassView.swift
Sources/OneWeave/DailyBriefings.swift
Sources/OneWeave/DataLeashSettings.swift
Sources/OneWeave/DataSeeder.swift
Sources/OneWeave/DecisionLog.swift
Sources/OneWeave/EssenceLedgerView.swift
Sources/OneWeave/FamilyPod.swift
Sources/OneWeave/GraphInsightGenerator.swift
Sources/OneWeave/HistoryView.swift
Sources/OneWeave/InsightGenerator.swift
Sources/OneWeave/InvisibleMentor.swift
Sources/OneWeave/LifeContext.swift
Sources/OneWeave/LifeGraph.swift
Sources/OneWeave/LifeGraphiOSIntegrations.swift
Sources/OneWeave/LivingGraphLoom.swift
Sources/OneWeave/LoomGeometry.swift
Sources/OneWeave/MasteryMapView.swift
Sources/OneWeave/MeaningThread.swift
Sources/OneWeave/MentorEchoBridge.swift
Sources/OneWeave/OnboardingView.swift
Sources/OneWeave/OneWeaveAPI.swift
Sources/OneWeave/OneWeaveApp.swift
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift
Sources/OneWeave/OneWeavePrototype.swift
Sources/OneWeave/OneWeaveSnapshotStore.swift
Sources/OneWeave/OneWeaveWidgetStubs.swift
Sources/OneWeave/P2PWeaveShare.swift
Sources/OneWeave/PortableExport.swift
Sources/OneWeave/PrivacyAudit.md
Sources/OneWeave/QuestService.swift
Sources/OneWeave/QuestsView.swift
Sources/OneWeave/QuickCaptureInbox.swift
Sources/OneWeave/RelationshipDecayTracker.swift
Sources/OneWeave/ResonanceOracle.swift
Sources/OneWeave/ResonanceOracleSheet.swift
Sources/OneWeave/SacredEcho.swift
Sources/OneWeave/SchemaMigrationPlan.swift
Sources/OneWeave/SettingsView.swift
Sources/OneWeave/StateMachineIndicator.swift
Sources/OneWeave/StewardshipThread.swift
Sources/OneWeave/Thread.swift
Sources/OneWeave/ThreadDetailView.swift
Sources/OneWeave/ThreadsOverviewView.swift
Sources/OneWeave/TimelineEvent.swift
Sources/OneWeave/TimelineService.swift
Sources/OneWeave/WeaveQuest.swift
Sources/OneWeave/WeaveSummaryView.swift
Sources/OneWeave/iOSServiceIntegrations.swift

 succeeded in 0ms:
ARCHITECTURE.md:19:│ • LifeContext    │    │ • SacredEcho      │         │ • DataLeashSettings│
ARCHITECTURE.md:22:│ • WeaveQuest     │    │ • ResonanceOracle │         │    /public)       │
ARCHITECTURE.md:45:WeaveQuest.complete(reflectionText: "...")       [reflection gate #1]
ARCHITECTURE.md:53:        │           isUserReflection: true,        [consent gate #3]
ARCHITECTURE.md:89:                            with isUserReflection=false (it's not the user's
ARCHITECTURE.md:95:1. **Reflection gate** — every `commit`-shaped function takes a
ARCHITECTURE.md:98:2. **Data Leash gate** — every integration path reads `DataLeashPolicy.
ARCHITECTURE.md:102:3. **Consent gate** — `LifeEntity.isUserReflection: Bool` distinguishes
ARCHITECTURE.md:104:   synthesizes from `isUserReflection == true`.
ARCHITECTURE.md:105:4. **isUserReflection gate** — Sacred Echo plaintext is decrypted only
ARCHITECTURE.md:108:5. **Fail-closed crypto gate** — SacredEchoCipher generates a Keychain
ARCHITECTURE.md:115:  (SacredEchoStore, AppLifecycleCoordinator, GraphInsightGenerator,
PRIVACY.md:42:### Gate 1: Reflection gate
PRIVACY.md:46:`ReflectionError.empty` or returns an empty result.
PRIVACY.md:49:- `WeaveQuest.complete(reflectionText:)` — must be non-empty
PRIVACY.md:54:- `SacredEchoStore.open(...)` — implicit (decree + plaintext required)
PRIVACY.md:55:- `SacredEchoStore.handDeliver(...:deliveryReflection:)` — must be non-empty
PRIVACY.md:56:- `SacredEchoStore.release(...:releaseReflection:)` — must be non-empty
PRIVACY.md:57:- `FamilyPodPolicy.exit(...:exitReflection:)` — must be ≥20 chars
PRIVACY.md:58:- `PortableExportBuilder.build(...:userIntentReflection:leash:)` — must be non-empty
PRIVACY.md:63:Every iOS system integration reads `DataLeashPolicy.currentLeash(in:
PRIVACY.md:82:### Gate 3: Consent gate (isUserReflection)
PRIVACY.md:84:`LifeEntity.isUserReflection: Bool` distinguishes user-authored content
PRIVACY.md:91:  `isUserReflection == true` are added to `reflections`.
PRIVACY.md:92:- `SacredEchoStore.seal(...:into:modelContext:)` — the life-graph
PRIVACY.md:94:  `isUserReflection = false` (the echo's plaintext is not the user's
PRIVACY.md:96:- `PortableExportBuilder` — only entities with `isUserReflection == true`
PRIVACY.md:97:  AND `leash.permitsReflections == true` have their `summary` text
PRIVACY.md:109:- `SacredEchoStore.open(...)` — throws `.notYetUnlocked` if
PRIVACY.md:118:SacredEchoCipher generates a 256-bit seed on first launch and persists
.specify/specs/003-production-readiness/spec.md:19:3. **What requires Mac work** to complete (Xcode project, Widget Extension target, App Group, build/test on device)
.specify/specs/003-production-readiness/spec.md:77:**Independent test**: Open Mentor → Input current decision → Receive 3 MentorTurns quoting from past journal entries marked `isUserReflection=true`.
.specify/specs/003-production-readiness/spec.md:80:1. **Given** user has 10+ journal entries with `isUserReflection=true`, **When** Mentor synthesizes, **Then** only those entries are quoted (never system-generated content)
.specify/specs/003-production-readiness/spec.md:85:- Zero `isUserReflection=true` entries: Mentor returns "Write your first reflection to begin" prompt
.specify/specs/003-production-readiness/spec.md:86:- Reflection text empty: filtered out (gated by `LifeEntity.isUserReflection` — caught by Nemotron review)
.specify/specs/003-production-readiness/spec.md:102:1. **Given** user toggles `healthKit = false` in `DataLeashSettingsRecord`, **When** any code path attempts `HealthIntegration.read()`, **Then** `currentLeash(in: ModelContext)` returns `false` BEFORE any HealthKit call, and the call is short-circuited
.specify/specs/003-production-readiness/spec.md:124:1. **Given** CognitiveLoadInputs `{calendarEventsNext4Hours: 8, openQuests: 15, openThreads: 6, sleepDebt: 0.8, daysSinceReflection: 4, amplifierLoad: 0.6}`, **When** `CognitiveLoad.compute()` runs, **Then** score is in [0.85, 0.95] with trend = rising
.specify/specs/003-production-readiness/spec.md:311:- Reflection gates prevent accidental state changes
.specify/specs/003-production-readiness/spec.md:339:- `DataLeashSettingsRecord` — privacy toggles
.specify/specs/003-production-readiness/spec.md:340:- `SacredEcho` — encrypted time-capsule messages
.specify/specs/003-production-readiness/spec.md:341:- `WeaveQuest` — gamified challenges
.specify/specs/003-production-readiness/spec.md:347:- `CognitiveLoadTrend`: rising | steadyHigh | falling | steadyLow
.specify/specs/003-production-readiness/spec.md:365:- WidgetKit (widget extension target)
.specify/specs/003-production-readiness/spec.md:366:- AppIntents (Siri + Shortcuts)
.specify/specs/003-production-readiness/spec.md:379:- CloudKit (sync would compromise local-first promise)
.specify/specs/003-production-readiness/spec.md:402:1. **Create Xcode project** with iOS 17+ target + Widget Extension + App Group `group.com.oneweave`
.specify/specs/003-production-readiness/spec.md:404:3. **Connect Widgets** (`HarmonyWidget`, `QuestWidget`, `OneWeaveLiveActivityAttributes`) to snapshot store
.specify/specs/003-production-readiness/spec.md:405:4. **AppIntents** registration (`LogWeaveIntent`, `CompleteQuestIntent`, `ShowHarmonyIntent`)
Sources/OneWeave/PortableExport.swift:34://  Reflection-gated:
Sources/OneWeave/PortableExport.swift:37://    `isUserReflection == true`. We never silently export reflections.
Sources/OneWeave/PortableExport.swift:68:    /// Reflections are NEVER included in this tier.
Sources/OneWeave/PortableExport.swift:87:    public var permitsReflections: Bool {
Sources/OneWeave/PortableExport.swift:147:    public let userIntentReflection: String  // the user's written reason
Sources/OneWeave/PortableExport.swift:160:        userIntentReflection: String,
Sources/OneWeave/PortableExport.swift:172:        self.userIntentReflection = userIntentReflection
Sources/OneWeave/PortableExport.swift:182:    case fullBundleRequiresReflection(minChars: Int)
Sources/OneWeave/PortableExport.swift:192:        case .fullBundleRequiresReflection(let min):
Sources/OneWeave/PortableExport.swift:209:    public static let fullBundleMinReflectionChars: Int = 30
Sources/OneWeave/PortableExport.swift:265:        if leash.permitsReflections && entity.isUserReflection {
Sources/OneWeave/PortableExport.swift:377:        echoes: [SacredEcho],
Sources/OneWeave/PortableExport.swift:396:                if let plain = try? SacredEchoCipher.open(
Sources/OneWeave/PortableExport.swift:403:                    md += "**Reflection (decrypted):**\n\n"
Sources/OneWeave/PortableExport.swift:426:        echoes: [SacredEcho],
Sources/OneWeave/PortableExport.swift:428:        userIntentReflection: String,
Sources/OneWeave/PortableExport.swift:437:        let trimmed = userIntentReflection.trimmingCharacters(in: .whitespacesAndNewlines)
Sources/OneWeave/PortableExport.swift:439:            guard trimmed.count >= PortableExportPolicy.fullBundleMinReflectionChars else {
Sources/OneWeave/PortableExport.swift:440:                throw PortableExportError.fullBundleRequiresReflection(
Sources/OneWeave/PortableExport.swift:441:                    min: PortableExportPolicy.fullBundleMinReflectionChars
Sources/OneWeave/PortableExport.swift:488:        let reflectionCount = entities.filter { $0.isUserReflection }.count
Sources/OneWeave/PortableExport.swift:495:            reflectionCount: leash.permitsReflections ? reflectionCount : 0,
Sources/OneWeave/PortableExport.swift:498:            userIntentReflection: trimmed,
Sources/OneWeave/PortableExport.swift:538:            userIntentReflection: bundle.manifest.userIntentReflection,
Sources/OneWeave/SettingsView.swift:8:    @Query private var quests: [WeaveQuest]
Sources/OneWeave/SettingsView.swift:52:                        Text("Completed quests: \(ctx.completedQuestCount) (reflections drive full mastery)")
Sources/OneWeave/SettingsView.swift:106:            gamif["completed_quests"] = ctx.completedQuestCount
Sources/OneWeave/SettingsView.swift:107:            gamif["active_quests_count"] = ctx.activeQuests.count
Sources/OneWeave/SettingsView.swift:129:        try? modelContext.delete(model: WeaveQuest.self)
Sources/OneWeave/LoomGeometry.swift:14://             currentSeason → palette + breath rate
Sources/OneWeave/LoomGeometry.swift:151:public enum LoomSeason: String, CaseIterable {
Sources/OneWeave/LoomGeometry.swift:174:    public static func forSeason(_ season: LoomSeason) -> LoomPalette {
Sources/OneWeave/LoomGeometry.swift:212:    public let season: LoomSeason
Sources/OneWeave/LoomGeometry.swift:219:        season: LoomSeason,
Sources/OneWeave/LoomGeometry.swift:322:        season: LoomSeason,
Sources/OneWeave/LoomGeometry.swift:353:        let palette = LoomPalette.forSeason(input.season)
Sources/OneWeave/DailyBriefings.swift:18://    2. Reflection-gated. Evening review requires at least one reflection
Sources/OneWeave/DailyBriefings.swift:69:    case priorities(quests: [BriefQuest])
Sources/OneWeave/DailyBriefings.swift:110:public struct BriefQuest: Codable, Equatable {
Sources/OneWeave/DailyBriefings.swift:176:    public var wroteReflectionToday: Bool {
Sources/OneWeave/DailyBriefings.swift:212:        cognitiveLoad: CognitiveLoadReading? = nil,
Sources/OneWeave/DailyBriefings.swift:279:        let openQuests = context.quests
Sources/OneWeave/DailyBriefings.swift:283:            .map { BriefQuest(id: $0.id, title: $0.title, isHeavy: true, priorityHint: 3) }
Sources/OneWeave/DailyBriefings.swift:284:        if !openQuests.isEmpty {
Sources/OneWeave/DailyBriefings.swift:285:            sections.append(.priorities(quests: Array(openQuests)))
Sources/OneWeave/DailyBriefings.swift:289:        // Mac side wires this from real SacredEcho queries.
Sources/OneWeave/DailyBriefings.swift:312:        cognitiveLoad: CognitiveLoadReading? = nil,
Sources/OneWeave/DailyBriefings.swift:313:        yesterdayCognitiveLoad: CognitiveLoadReading? = nil,
Sources/OneWeave/DailyBriefings.swift:329:                && ($0.note.contains("reflection") || $0.note.contains("Reflection"))
Sources/OneWeave/DailyBriefings.swift:336:            - (yesterdayCognitiveLoad.map { $0.score } ?? 0.5)
Sources/OneWeave/DailyBriefings.swift:409:    /// the real SacredEcho SwiftData query.
Sources/OneWeave/CompassView.swift:6:// No network, no external calls, no training. Export/clear works via Settings. Reflection gates anti-addiction.
Sources/OneWeave/CompassView.swift:12:    @Query private var allQuests: [WeaveQuest]
Sources/OneWeave/CompassView.swift:31:    // Quests + reflection gate (per spec: reflection required for full award)
Sources/OneWeave/CompassView.swift:32:    @State private var suggestedQuests: [WeaveQuest] = []
Sources/OneWeave/CompassView.swift:33:    @State private var showQuestReflection = false
Sources/OneWeave/CompassView.swift:34:    @State private var selectedQuest: WeaveQuest? = nil
Sources/OneWeave/CompassView.swift:36:    @State private var questService: QuestService? = QuestService.shared
Sources/OneWeave/CompassView.swift:168:                    // Production Quests UI - full suggested list + reflection gate (prominent, always visible)
Sources/OneWeave/CompassView.swift:171:                        ForEach(suggestedQuests.prefix(4)) { q in
Sources/OneWeave/CompassView.swift:179:                                    selectedQuest = q
Sources/OneWeave/CompassView.swift:180:                                    showQuestReflection = true
Sources/OneWeave/CompassView.swift:189:                        if suggestedQuests.isEmpty {
Sources/OneWeave/CompassView.swift:190:                            Text("Quests generated from your threads and state. Tap to weave.")
Sources/OneWeave/CompassView.swift:197:            // Production Quests - prominent full list + reflection gate
Sources/OneWeave/CompassView.swift:200:                ForEach(allQuests.prefix(5)) { q in
Sources/OneWeave/CompassView.swift:202:                        selectedQuest = q
Sources/OneWeave/CompassView.swift:203:                        showQuestReflection = true
Sources/OneWeave/CompassView.swift:264:                            // Season indicator (production production, calm UI)
Sources/OneWeave/CompassView.swift:266:                                Text("Season: \(ctx.values["season"] ?? ctx.currentSeason)")
Sources/OneWeave/CompassView.swift:270:                                Button("Change Season") {
Sources/OneWeave/CompassView.swift:271:                                    ctx.changeSeason(to: "Autumn")
Sources/OneWeave/CompassView.swift:272:                                    weaveFeedback = "Season shifted. Reflection gate open."
Sources/OneWeave/CompassView.swift:359:                        NavigationLink(value: "QuestsView") {
Sources/OneWeave/CompassView.swift:360:                            Label("Quests", systemImage: "list.bullet.rectangle")
Sources/OneWeave/CompassView.swift:414:                                        suggestedQuests = qs.generateSuggestedQuests(from: c, recentEvents: recentEvents)
Sources/OneWeave/CompassView.swift:445:                    // Quests section + reflection gate (insert after quick capture per task)
Sources/OneWeave/CompassView.swift:446:                    // Suggested quests from QuestService; reflection required for full essence award
Sources/OneWeave/CompassView.swift:448:                        Text("Suggested Quests")
Sources/OneWeave/CompassView.swift:452:                        if suggestedQuests.isEmpty {
Sources/OneWeave/CompassView.swift:457:                            ForEach(suggestedQuests, id: \.id) { quest in
Sources/OneWeave/CompassView.swift:481:                                            selectedQuest = quest
Sources/OneWeave/CompassView.swift:483:                                            showQuestReflection = true
Sources/OneWeave/CompassView.swift:529:            case "QuestsView":
Sources/OneWeave/CompassView.swift:530:                QuestsView()
Sources/OneWeave/CompassView.swift:543:                let qs = (try? modelContext.fetch(FetchDescriptor<WeaveQuest>())) ?? []
Sources/OneWeave/CompassView.swift:544:                c.pushSnapshotToWidgets(from: qs)
Sources/OneWeave/CompassView.swift:548:            questService = QuestService.shared
Sources/OneWeave/CompassView.swift:565:                suggestedQuests = questService?.generateSuggestedQuests(from: c, recentEvents: recentEvents) ?? []
Sources/OneWeave/CompassView.swift:571:        .sheet(isPresented: $showQuestReflection) {
Sources/OneWeave/CompassView.swift:573:                if let quest = selectedQuest, let ctx = context {
Sources/OneWeave/CompassView.swift:574:                    Text("Quest Reflection Gate")
Sources/OneWeave/CompassView.swift:594:                    Text("✧ Reflection unlocks full essence. Be specific about IRL action & insight.")
Sources/OneWeave/CompassView.swift:601:                            showQuestReflection = false
Sources/OneWeave/CompassView.swift:610:                                qs.completeWithReflection(questId: quest.id, reflection: trimmed, context: ctx, modelContext: modelContext)
Sources/OneWeave/CompassView.swift:613:                                let fb = "✧ Quest +\(Int(awarded)) Essence (reflected) • L\(ctx.weaveLevel) • 🔥\(ctx.globalWeaveStreak) • Ripple complete"
Sources/OneWeave/CompassView.swift:623:                                    suggestedQuests = qs.generateSuggestedQuests(from: c, recentEvents: recentEvents)
Sources/OneWeave/CompassView.swift:625:                                showQuestReflection = false
Sources/OneWeave/CompassView.swift:636:                    Button("Close") { showQuestReflection = false }
Sources/OneWeave/QuestsView.swift:4:// Phase 6: Lightweight QuestsView (or use as modal). Lists suggested/active + reflection flow.
Sources/OneWeave/QuestsView.swift:5:// Reuses QuestService + LifeContext. Calm, IRL-first. Keep simple.
Sources/OneWeave/QuestsView.swift:6:struct QuestsView: View {
Sources/OneWeave/QuestsView.swift:9:    @State private var showReflectionFor: UUID?
Sources/OneWeave/QuestsView.swift:17:                    Text("🎯 Quests")
Sources/OneWeave/QuestsView.swift:23:                    let suggested = QuestService.shared.generateSuggestedQuests(from: ctx, recentEvents: [])
Sources/OneWeave/QuestsView.swift:24:                    let active = ctx.activeQuests
Sources/OneWeave/QuestsView.swift:38:                                        QuestService.shared.acceptQuest(q, context: ctx, modelContext: modelContext)
Sources/OneWeave/QuestsView.swift:63:                    Button("Open Reflection for Last") {
Sources/OneWeave/QuestsView.swift:65:                            showReflectionFor = last
Sources/OneWeave/QuestsView.swift:72:                    if let qid = showReflectionFor {
Sources/OneWeave/QuestsView.swift:77:                            Button("Complete with Reflection") {
Sources/OneWeave/QuestsView.swift:78:                                QuestService.shared.completeWithReflection(questId: qid, reflection: reflectionText, context: ctx, modelContext: modelContext)
Sources/OneWeave/QuestsView.swift:81:                                showReflectionFor = nil
Sources/OneWeave/QuestsView.swift:89:                    Text("All local. Reflection gate for anti-grind. See History for ripples.")
Sources/OneWeave/CognitiveLoad.swift:2://  CognitiveLoad.swift
Sources/OneWeave/CognitiveLoad.swift:22://    3. Reflection-gated for any commitment action. A score ≥ 0.85 can
Sources/OneWeave/CognitiveLoad.swift:34://    - Persisting historical scores. We expose a `CognitiveLoadReading`
Sources/OneWeave/CognitiveLoad.swift:49:/// in the Mac-side settings UI by exposing a `CognitiveLoadProfile`.
Sources/OneWeave/CognitiveLoad.swift:50:public enum CognitiveLoadComponent: String, Codable, CaseIterable {
Sources/OneWeave/CognitiveLoad.swift:55:    case recentReflectionGap     // days since last reflection (high = unprocessed)
Sources/OneWeave/CognitiveLoad.swift:61:public enum CognitiveLoadWeights {
Sources/OneWeave/CognitiveLoad.swift:66:    public static let recentReflectionGap: Double = 0.15
Sources/OneWeave/CognitiveLoad.swift:73:            + recentReflectionGap + activeAmplifierLoad
Sources/OneWeave/CognitiveLoad.swift:81:public struct CognitiveLoadReading: Codable, Equatable {
Sources/OneWeave/CognitiveLoad.swift:84:    public let trend: CognitiveLoadTrend
Sources/OneWeave/CognitiveLoad.swift:91:        trend: CognitiveLoadTrend,
Sources/OneWeave/CognitiveLoad.swift:105:public enum CognitiveLoadTrend: String, Codable, Equatable {
Sources/OneWeave/CognitiveLoad.swift:119:public enum CognitiveLoadThresholds {
Sources/OneWeave/CognitiveLoad.swift:134:public struct CognitiveLoadInputs {
Sources/OneWeave/CognitiveLoad.swift:136:    public let openQuestCount: Int                  // 0..30 typical
Sources/OneWeave/CognitiveLoad.swift:142:    public let daysSinceLastReflection: Int         // 0..30
Sources/OneWeave/CognitiveLoad.swift:144:    public let previousReading: CognitiveLoadReading? // for trend
Sources/OneWeave/CognitiveLoad.swift:148:        openQuestCount: Int,
Sources/OneWeave/CognitiveLoad.swift:154:        daysSinceLastReflection: Int,
Sources/OneWeave/CognitiveLoad.swift:156:        previousReading: CognitiveLoadReading? = nil
Sources/OneWeave/CognitiveLoad.swift:159:        self.openQuestCount = openQuestCount
Sources/OneWeave/CognitiveLoad.swift:165:        self.daysSinceLastReflection = daysSinceLastReflection
Sources/OneWeave/CognitiveLoad.swift:173:public enum CognitiveLoad {
Sources/OneWeave/CognitiveLoad.swift:178:        from inputs: CognitiveLoadInputs,
Sources/OneWeave/CognitiveLoad.swift:180:    ) -> CognitiveLoadReading {
Sources/OneWeave/CognitiveLoad.swift:183:        let taskScore = normalizeOpenTasks(quests: inputs.openQuestCount, threads: inputs.openThreadCount)
Sources/OneWeave/CognitiveLoad.swift:192:        let reflectionScore = normalizeReflectionGap(days: inputs.daysSinceLastReflection)
Sources/OneWeave/CognitiveLoad.swift:197:            CognitiveLoadComponent.calendarDensity.rawValue: calendarScore,
Sources/OneWeave/CognitiveLoad.swift:198:            CognitiveLoadComponent.openTaskCount.rawValue: taskScore,
Sources/OneWeave/CognitiveLoad.swift:199:            CognitiveLoadComponent.sleepDebt.rawValue: sleepScore,
Sources/OneWeave/CognitiveLoad.swift:200:            CognitiveLoadComponent.hrvStress.rawValue: hrvScore,
Sources/OneWeave/CognitiveLoad.swift:201:            CognitiveLoadComponent.recentReflectionGap.rawValue: reflectionScore,
Sources/OneWeave/CognitiveLoad.swift:202:            CognitiveLoadComponent.activeAmplifierLoad.rawValue: amplifierScore
Sources/OneWeave/CognitiveLoad.swift:205:            calendarScore * CognitiveLoadWeights.calendarDensity +
Sources/OneWeave/CognitiveLoad.swift:206:            taskScore * CognitiveLoadWeights.openTaskCount +
Sources/OneWeave/CognitiveLoad.swift:207:            sleepScore * CognitiveLoadWeights.sleepDebt +
Sources/OneWeave/CognitiveLoad.swift:208:            hrvScore * CognitiveLoadWeights.hrvStress +
Sources/OneWeave/CognitiveLoad.swift:209:            reflectionScore * CognitiveLoadWeights.recentReflectionGap +
Sources/OneWeave/CognitiveLoad.swift:210:            amplifierScore * CognitiveLoadWeights.activeAmplifierLoad
Sources/OneWeave/CognitiveLoad.swift:226:        let shouldTrigger = score >= CognitiveLoadThresholds.weavePauseScore
Sources/OneWeave/CognitiveLoad.swift:229:        return CognitiveLoadReading(
Sources/OneWeave/CognitiveLoad.swift:238:    /// Convenience: derive CognitiveLoadInputs directly from LifeContext
Sources/OneWeave/CognitiveLoad.swift:240:    public static func inputs(from context: LifeContext, now: Date = Date()) -> CognitiveLoadInputs {
Sources/OneWeave/CognitiveLoad.swift:251:        let openQuests = context.quests.filter { !$0.isCompleted }.count
Sources/OneWeave/CognitiveLoad.swift:261:        // Reflection gap.
Sources/OneWeave/CognitiveLoad.swift:262:        let daysSinceReflection: Int
Sources/OneWeave/CognitiveLoad.swift:263:        if let last = context.lastReflectionAt {
Sources/OneWeave/CognitiveLoad.swift:264:            daysSinceReflection = max(0, Int(now.timeIntervalSince(last) / 86400))
Sources/OneWeave/CognitiveLoad.swift:266:            daysSinceReflection = 7 // assume a week if never written
Sources/OneWeave/CognitiveLoad.swift:276:        return CognitiveLoadInputs(
Sources/OneWeave/CognitiveLoad.swift:278:            openQuestCount: openQuests,
Sources/OneWeave/CognitiveLoad.swift:284:            daysSinceLastReflection: daysSinceReflection,
Sources/OneWeave/CognitiveLoad.swift:286:            previousReading: context.previousCognitiveLoad
Sources/OneWeave/CognitiveLoad.swift:302:    /// Quests are heavier than threads (they require explicit commitment).
Sources/OneWeave/CognitiveLoad.swift:338:    /// Reflection gap: 0 days = 0.0, 7+ days = 1.0.
Sources/OneWeave/CognitiveLoad.swift:340:    private static func normalizeReflectionGap(days: Int) -> Double {
Sources/OneWeave/CognitiveLoad.swift:346:        previous: CognitiveLoadReading?,
Sources/OneWeave/CognitiveLoad.swift:348:    ) -> CognitiveLoadTrend {
Sources/OneWeave/CognitiveLoad.swift:357:        if absDelta < CognitiveLoadThresholds.significantDelta * 0.5 {
Sources/OneWeave/CognitiveLoad.swift:359:            if current >= CognitiveLoadThresholds.elevatedScore { return .steadyHigh }
Sources/OneWeave/CognitiveLoad.swift:360:            if current <= CognitiveLoadThresholds.calmScore { return .steadyLow }
Sources/OneWeave/CognitiveLoad.swift:374:/// principle as `WeaveQuest.complete(reflectionText:)`, but at the
Sources/OneWeave/CognitiveLoad.swift:376:public enum CognitiveLoadPauseError: Error, LocalizedError {
Sources/OneWeave/CognitiveLoad.swift:387:                (above \(Int(CognitiveLoadThresholds.weavePauseScore * 100))%). \
Sources/OneWeave/CognitiveLoad.swift:402:    ///   - reading: The current CognitiveLoadReading.
Sources/OneWeave/CognitiveLoad.swift:404:    /// - Throws: `CognitiveLoadPauseError.reflectionRequired` if the
Sources/OneWeave/CognitiveLoad.swift:407:        reading: CognitiveLoadReading,
Sources/OneWeave/CognitiveLoad.swift:417:            throw CognitiveLoadPauseError.reflectionRequired(
Sources/OneWeave/CognitiveLoad.swift:441:/// exist (BodyThread is optional, previousCognitiveLoad is ephemeral).
Sources/OneWeave/CognitiveLoad.swift:470:    /// The previous CognitiveLoadReading (for trend computation).
Sources/OneWeave/CognitiveLoad.swift:474:    var previousCognitiveLoad: CognitiveLoadReading? {
Sources/OneWeave/CognitiveLoad.swift:476:            guard !self.previousCognitiveLoadReadingJSON.isEmpty,
Sources/OneWeave/CognitiveLoad.swift:477:                  let data = self.previousCognitiveLoadReadingJSON.data(using: .utf8),
Sources/OneWeave/CognitiveLoad.swift:478:                  let decoded = try? JSONDecoder().decode(CognitiveLoadReading.self, from: data)
Sources/OneWeave/CognitiveLoad.swift:486:                self.previousCognitiveLoadReadingJSON = json
Sources/OneWeave/CognitiveLoad.swift:488:                self.previousCognitiveLoadReadingJSON = ""
Sources/OneWeave/CognitiveLoad.swift:493:    // CognitiveLoadReading is already Codable (declared at the struct definition
Sources/OneWeave/MasteryMapView.swift:77:                        Text("Completed quests: \(ctx.completedQuestCount) (reflections drive full mastery)")
Sources/OneWeave/OneWeavePrototype.swift:4:// Expanded Phase 7: explicit WeaveQuest persist verify (insert/save/query/export-JSON via Settings sim) + ThreadDetail gamif sim.
Sources/OneWeave/OneWeavePrototype.swift:20:    @Query private var quests: [WeaveQuest]
Sources/OneWeave/OneWeavePrototype.swift:22:    private var widgetPreviewQuests: [WeaveQuest] {
Sources/OneWeave/OneWeavePrototype.swift:50:                        Button("Start First Weave + Quest") {
Sources/OneWeave/OneWeavePrototype.swift:54:                                let firstQ = WeaveQuest(title: "First weave: notice one breath", description: "IRL: pause for 3 breaths. Log how it felt.", domains: ["Self"], baseEssence: 5)
Sources/OneWeave/OneWeavePrototype.swift:56:                                ctx.activeQuests.append(firstQ.id)
Sources/OneWeave/OneWeavePrototype.swift:91:        let q = WeaveQuest(title: "Roundtrip Test Quest", description: "Verify persist/export", domains: ["Self"], baseEssence: 7)
Sources/OneWeave/OneWeavePrototype.swift:95:        demoNote = "Quest inserted. Check Settings Export for it in quests list. Mastery/ledger updated via context."
Sources/OneWeave/OneWeavePrototype.swift:99:Button("Test WeaveQuest Persistence + Export") {
Sources/OneWeave/OneWeavePrototype.swift:100:    let testQ = WeaveQuest(title: "Test persist quest", description: "Verify save/export", domains: ["Self"], baseEssence: 5, estimatedIRLMinutes: 3)
Sources/OneWeave/OneWeavePrototype.swift:103:    demoNote = "WeaveQuest inserted and saved. Check export for it in gamif JSON."
Sources/OneWeave/OneWeavePrototype.swift:107:                                simulateBusySeasonGoal()
Sources/OneWeave/OneWeavePrototype.swift:123:                    _ = ctx.activeQuests.count
Sources/OneWeave/OneWeavePrototype.swift:126:                    let export = "Essence: \(ctx.essenceDisplay)\nSeason: \(ctx.values["season"] ?? ctx.currentSeason)\nMastery total: \(mastery)\nLedger last: \(ctx.essenceLedger.last ?? "none")"
Sources/OneWeave/OneWeavePrototype.swift:129:                    ctx.changeSeason(to: "Summer")
Sources/OneWeave/OneWeavePrototype.swift:132:            Button("Complete Season Reflection") {
Sources/OneWeave/OneWeavePrototype.swift:134:                    ctx.completeSeasonReflection(note: "Harvested insights from the weave this season.")
Sources/OneWeave/OneWeavePrototype.swift:135:                    demoNote = "Season reflection complete +10 Essence + burst. Chapter summary emitted."
Sources/OneWeave/OneWeavePrototype.swift:151:            Button("Forge Custom Quest") {
Sources/OneWeave/OneWeavePrototype.swift:152:                if let forged = QuestService.shared.forgeCustomQuest(
Sources/OneWeave/OneWeavePrototype.swift:174:        // Phase 6: Lightweight views demo (full sheets for QuestsView, EssenceLedgerView, MasteryMapView)
Sources/OneWeave/OneWeavePrototype.swift:177:            Button("Quests (list + reflect)") {
Sources/OneWeave/OneWeavePrototype.swift:179:                demoNote = "QuestsView: suggested + active + reflection gate (see QuestsView.swift)"
Sources/OneWeave/OneWeavePrototype.swift:191:// Phase 7 test harness note (production verification expanded): real persistence test for WeaveQuest + ThreadDetail gamif sims + mastery/streak checks + export verification. All local-only.
Sources/OneWeave/OneWeavePrototype.swift:271:                            // Quest demo (production gamif - generate + reflect per 002 spec)
Sources/OneWeave/OneWeavePrototype.swift:272:                            Button("Generate Context-Aware Quests") {
Sources/OneWeave/OneWeavePrototype.swift:274:                                    let qs = QuestService.shared
Sources/OneWeave/OneWeavePrototype.swift:275:                                    let newQuests = qs.generateSuggestedQuests(from: ctx, recentEvents: events)
Sources/OneWeave/OneWeavePrototype.swift:276:                                    demoNote = "Generated \(newQuests.count) quests. IRL examples: \(newQuests.map { $0.title }.joined(separator: "; ")). Switch to Compass tab."
Sources/OneWeave/OneWeavePrototype.swift:281:                            Button("Demo: Complete Quest + Reflection (full award)") {
Sources/OneWeave/OneWeavePrototype.swift:283:                                    let qs = QuestService.shared
Sources/OneWeave/OneWeavePrototype.swift:284:                                    let demoQuest = WeaveQuest(title: "Demo quest: Reflect on today's win", description: "Note one IRL action from a recent weave and the cross-domain effect.", domains: ["Self"], baseEssence: 12, estimatedIRLMinutes: 5, validationHints: "Be specific about the action and insight.")
Sources/OneWeave/OneWeavePrototype.swift:285:                                    ctx.activeQuests.append(demoQuest.id)
Sources/OneWeave/OneWeavePrototype.swift:287:                                    qs.completeWithReflection(questId: demoQuest.id, reflection: reflection, context: ctx, modelContext: modelContext)
Sources/OneWeave/OneWeavePrototype.swift:288:                                    demoNote = "Quest complete with reflection! +10 Essence (full award). Streak: \(ctx.globalWeaveStreak). Check Compass HUD."
Sources/OneWeave/OneWeavePrototype.swift:295:                            // create WeaveQuest, save via context (insert to modelContext), verify in container (fetch + @Query), export data, check mastery/streak/essence updates.
Sources/OneWeave/OneWeavePrototype.swift:297:                            // Re-verifies WeaveQuest persistence + gamif cascade per spec/tasks.
Sources/OneWeave/OneWeavePrototype.swift:299:                            Button("Real Persist Test: Create WeaveQuest + Save via Context") {
Sources/OneWeave/OneWeavePrototype.swift:301:                                let pQuest = WeaveQuest(
Sources/OneWeave/OneWeavePrototype.swift:309:                                modelContext.insert(pQuest)  // save to SwiftData container
Sources/OneWeave/OneWeavePrototype.swift:310:                                if !ctx.activeQuests.contains(pQuest.id) {
Sources/OneWeave/OneWeavePrototype.swift:311:                                    ctx.activeQuests.append(pQuest.id)
Sources/OneWeave/OneWeavePrototype.swift:314:                                let initEvent = TimelineEvent(thread: "Self", type: "persist_quest_created", payload: ["title": pQuest.title], affectsEnergy: true, linkedThreads: ["Meaning"])
Sources/OneWeave/OneWeavePrototype.swift:316:                                    svc.emitEvent(thread: "Self", type: "persist_quest_created", payload: ["title": pQuest.title], affectsEnergy: true, linkedThreads: ["Meaning"])
Sources/OneWeave/OneWeavePrototype.swift:319:                                demoNote = "✅ WeaveQuest created + inserted to container (persisted). ID prefix: \(pQuest.id.uuidString.prefix(8)). ActiveQuests: \(ctx.activeQuests.count). Now use Verify button."
Sources/OneWeave/OneWeavePrototype.swift:325:                                let qDesc = FetchDescriptor<WeaveQuest>()
Sources/OneWeave/OneWeavePrototype.swift:327:                                let testQuestIn = inContainer.first(where: { $0.title.contains("Persist Verify") || $0.domains.contains("Meaning") })
Sources/OneWeave/OneWeavePrototype.swift:332:                                let beforeC = ctx.completedQuestCount
Sources/OneWeave/OneWeavePrototype.swift:335:                                ctx.completedQuestCount += 1
Sources/OneWeave/OneWeavePrototype.swift:336:                                if let tid = testQuestIn?.id {
Sources/OneWeave/OneWeavePrototype.swift:337:                                    ctx.activeQuests.removeAll { $0 == tid }
Sources/OneWeave/OneWeavePrototype.swift:352:                                let exportSnippet = "EXPORT CHECK (from harness): Essence=\(Int(ctx.weaveEssence)) L\(ctx.weaveLevel) | Streak=\(ctx.globalWeaveStreak) grace=\(ctx.graceDaysUsed)/\(ctx.maxGraceDays) | MasteryMeaning=L\(afterM) | CompletedQuests=\(ctx.completedQuestCount) | Active=\(ctx.activeQuests.count) | ContainerQuests=\(qCount) | Ledger last: \(ctx.essenceLedger.suffix(2)) | All local SwiftData verified."
Sources/OneWeave/OneWeavePrototype.swift:354:                                demoNote = "✅ VERIFY: \(qCount) WeaveQuests in SwiftData container (found test: \(testQuestIn?.title ?? \"n/a\")). Mastery M: \(beforeM)->\(afterM) | Streak: \(beforeS)->\(afterS) | Essence: \(Int(beforeE))->\(Int(afterE)) | Completed: \(beforeC)->\(ctx.completedQuestCount). \(exportSnippet)"
Sources/OneWeave/OneWeavePrototype.swift:358:                            // Explicit persistence verification for WeaveQuest per expanded harness task:
Sources/OneWeave/OneWeavePrototype.swift:363:                                let q = WeaveQuest(
Sources/OneWeave/OneWeavePrototype.swift:375:                                let fetchDesc = FetchDescriptor<WeaveQuest>()
Sources/OneWeave/OneWeavePrototype.swift:390:                                gamif["completed_quests"] = ctx.completedQuestCount
Sources/OneWeave/OneWeavePrototype.swift:391:                                gamif["active_quests_count"] = ctx.activeQuests.count
Sources/OneWeave/OneWeavePrototype.swift:395:                                var exportQuests = quests.map { ["id": $0.id.uuidString, "title": $0.title, "status": $0.status.rawValue, "reflection": $0.reflectionNote ?? ""] }
Sources/OneWeave/OneWeavePrototype.swift:396:                                if !exportQuests.contains(where: { ($0["title"] as? String ?? "") == uniqueTitle }) {
Sources/OneWeave/OneWeavePrototype.swift:397:                                    exportQuests.append(["id": q.id.uuidString, "title": q.title, "status": "Pending", "reflection": ""])
Sources/OneWeave/OneWeavePrototype.swift:399:                                gamif["quests"] = exportQuests
Sources/OneWeave/OneWeavePrototype.swift:404:                                // realistic: add to activeQuests
Sources/OneWeave/OneWeavePrototype.swift:405:                                if !ctx.activeQuests.contains(q.id) {
Sources/OneWeave/OneWeavePrototype.swift:406:                                    ctx.activeQuests.append(q.id)
Sources/OneWeave/OneWeavePrototype.swift:409:                                demoNote = "✅ EXPLICIT PERSIST VERIFY: Inserted+saved '\(uniqueTitle)'. Query back via fetch: \(queriedViaFetch), via @Query: \(queriedViaQuery). Present in Settings export JSON: \(inExportJSON). Total quests in JSON: \(exportQuests.count). Roundtrip complete (insert/save/query/export check). Check real Settings > Export for matching data."
Sources/OneWeave/OneWeavePrototype.swift:416:                                let tdQuest = WeaveQuest(
Sources/OneWeave/OneWeavePrototype.swift:424:                                modelContext.insert(tdQuest)  // persist
Sources/OneWeave/OneWeavePrototype.swift:425:                                ctx.activeQuests.append(tdQuest.id)
Sources/OneWeave/OneWeavePrototype.swift:428:                                svc.emitEvent(thread: "CareKin", type: "quest_accepted_td_sim", payload: ["quest": tdQuest.title], affectsEnergy: true, linkedThreads: ["Self"])
Sources/OneWeave/OneWeavePrototype.swift:430:                                // reflect/complete sim (like submitReflection + completeWithReflection)
Sources/OneWeave/OneWeavePrototype.swift:432:                                QuestService.shared.completeWithReflection(questId: tdQuest.id, reflection: reflect, context: ctx, modelContext: modelContext)
Sources/OneWeave/OneWeavePrototype.swift:433:                                tdQuest.reflectionNote = reflect
Sources/OneWeave/OneWeavePrototype.swift:434:                                tdQuest.status = .reflected
Sources/OneWeave/OneWeavePrototype.swift:435:                                tdQuest.completedAt = Date()
Sources/OneWeave/OneWeavePrototype.swift:438:                                ctx.completedQuestCount += 1
Sources/OneWeave/OneWeavePrototype.swift:439:                                ctx.activeQuests.removeAll { $0 == tdQuest.id }
Sources/OneWeave/OneWeavePrototype.swift:453:                                demoNote = "✅ ThreadDetail + Gamif SIM: Quest persisted+reflected. CareKin mastery L\(ctx.masteryTiers["CareKin"] ?? 1) (Self L\(ctx.masteryTiers["Self"] ?? 1)), Streak=\(ctx.globalWeaveStreak), Harmony=\(Int(ctx.harmonyScore*100))%, Essence+12, quest reflected in container. Ripples to Self/Meaning emitted. (Matches ThreadDetailView full flow + persistence)."
Sources/OneWeave/OneWeavePrototype.swift:488:        // Mirrors OneWeaveWidgetStubs.swift exactly (Harmony + Quest views + mini tapestry)
Sources/OneWeave/OneWeavePrototype.swift:489:        // No WidgetKit target here (production, requires Xcode extension + App Group)
Sources/OneWeave/OneWeavePrototype.swift:491:            Text("Widget Previews (Production-ready sims - ready for Widget Extension target)").font(.caption).foregroundStyle(.secondary)
Sources/OneWeave/OneWeavePrototype.swift:495:                    Text("Harmony Widget").font(.caption.bold())
Sources/OneWeave/OneWeavePrototype.swift:498:                    if let qid = ctx.activeQuests.first, let q = quests.first(where: { $0.id == qid }) {
Sources/OneWeave/OneWeavePrototype.swift:499:                        Text("Quest: \(q.title)").font(.caption2).foregroundStyle(.secondary)
Sources/OneWeave/OneWeavePrototype.swift:509:                // Quest sim
Sources/OneWeave/OneWeavePrototype.swift:511:                    Text("Quest Widget").font(.caption.bold())
Sources/OneWeave/OneWeavePrototype.swift:552:        // Phase 8 production: Simple widget preview in prototype (sim only; mimics HarmonyWidgetView + QuestWidgetView using LifeContext snapshot data)
Sources/OneWeave/OneWeavePrototype.swift:553:        // This allows testing widget data shapes in harness without full WidgetKit target. Uses same fields as OneWeaveSnapshot.
Sources/OneWeave/OneWeavePrototype.swift:555:            Text("Widget Preview (Phase 8 production)").font(.caption).foregroundStyle(.secondary)
Sources/OneWeave/OneWeavePrototype.swift:562:                if let topQ = context.activeQuests.first {
Sources/OneWeave/OneWeavePrototype.swift:563:                    Text("Quest: \(topQ.title)")
Sources/OneWeave/OneWeavePrototype.swift:568:                    Text("Quest: (no active)")
Sources/OneWeave/OneWeavePrototype.swift:587:            // Quest widget sim (medium)
Sources/OneWeave/OneWeavePrototype.swift:591:                let simQuests = context.activeQuests.prefix(2)
Sources/OneWeave/OneWeavePrototype.swift:592:                if simQuests.isEmpty {
Sources/OneWeave/OneWeavePrototype.swift:596:                    ForEach(Array(simQuests)) { q in
Sources/OneWeave/OneWeavePrototype.swift:628:        // Phase 6: Lightweight views demo (full sheets for QuestsView, EssenceLedgerView, MasteryMapView)
Sources/OneWeave/OneWeavePrototype.swift:630:            Button("Quests (list + reflect)") {
Sources/OneWeave/OneWeavePrototype.swift:632:                demoNote = "QuestsView: suggested + active + reflection gate (see QuestsView.swift)"
Sources/OneWeave/OneWeavePrototype.swift:719:    private func simulateBusySeasonGoal() {
Sources/OneWeave/OneWeavePrototype.swift:779:    private func showQuestSummary() {
Sources/OneWeave/OneWeavePrototype.swift:781:            print("Quest summary: active \(ctx.activeQuests.count), completed \(ctx.completedQuestCount)")
Sources/OneWeave/OneWeavePrototype.swift:789:        .modelContainer(for: [LifeContext.self, TimelineEvent.self, WeaveQuest.self, BasicSelfThread.self, CareKinThread.self, MeaningThread.self])
Sources/OneWeave/OneWeavePrototype.swift:792:        // Seasons production demo (tied to LifeContext production)
Sources/OneWeave/OneWeavePrototype.swift:794:            Text("Seasons (production demo)").font(.caption).foregroundStyle(.secondary)
Sources/OneWeave/OneWeavePrototype.swift:796:                Text("Current: \(ctx.values["season"] ?? ctx.currentSeason) (changed: \(ctx.seasonChangeDate.formatted(.dateTime.month().day())))")
Sources/OneWeave/OneWeavePrototype.swift:798:                Button("Change Season → Summer") {
Sources/OneWeave/OneWeavePrototype.swift:799:                    ctx.changeSeason(to: "Summer")
Sources/OneWeave/OneWeavePrototype.swift:800:                    demoNote = "Season changed to Summer +20 Essence burst. Reflection gate now available."
Sources/OneWeave/OneWeavePrototype.swift:802:                Button("Complete Season Reflection") {
Sources/OneWeave/OneWeavePrototype.swift:803:                    ctx.completeSeasonReflection(note: "Reflected on cross-thread ripples and harmony this season.")
Sources/OneWeave/OneWeavePrototype.swift:804:                    demoNote = "Season reflection +10 Essence + chapter summary event."
Sources/OneWeave/OneWeavePrototype.swift:815:                let hasQuests = !ctx.activeQuests.isEmpty
Sources/OneWeave/OneWeavePrototype.swift:817:                let season = ctx.values["season"] ?? ctx.currentSeason
Sources/OneWeave/OneWeavePrototype.swift:819:                let exportData = "Ledger:\(hasLedger) Quests:\(hasQuests) Mastery:\(masterySum) Season:\(season)"
Sources/OneWeave/OneWeavePrototype.swift:827:                ctx.changeSeason(to: "Winter")
Sources/OneWeave/OneWeavePrototype.swift:829:                ctx.completeSeasonReflection(note: "Full roundtrip test reflection")
Sources/OneWeave/OneWeavePrototype.swift:830:                let export = "Season: \(ctx.currentSeason) Ledger: \(ctx.essenceLedger.count) Quests: \(ctx.activeQuests.count) Mastery: \(ctx.masteryTiers.values.reduce(0,+))"
Sources/OneWeave/OneWeavePrototype.swift:852:        let circle = P2PWeaveShare.createCircleShare(from: Array(sampleEntities), requireReflection: true)
Sources/OneWeave/OneWeavePrototype.swift:959:                    lifeContext.pushSnapshotToWidgets()
Sources/OneWeave/MeaningThread.swift:272:// Global best practice: Focuses on real-world legacy and analog stories. 
Sources/OneWeave/QuickCaptureInbox.swift:16://      - Reflection patterns ("I feel", "today I", "noticed")
Sources/OneWeave/QuickCaptureInbox.swift:28://    3. Reflection-gated for destinations that need it. If the classifier
Sources/OneWeave/QuickCaptureInbox.swift:68:    public var requiresReflection: Bool {
Sources/OneWeave/QuickCaptureInbox.swift:193:        // Question marks / "I need to" / "I should" patterns.
Sources/OneWeave/QuickCaptureInbox.swift:305:        // Question mark at end of input that's a choice question.
Sources/OneWeave/BodyThreadWeaver.swift:9://  Reflection-gated. Honors Data Leash (privacy-first, opt-in only).
Sources/OneWeave/BodyThreadWeaver.swift:101:    public static func liveReading(leash: DataLeashState) async -> BodyThreadReading? {
Sources/OneWeave/InvisibleMentor.swift:17://    3. Reflection-gated always. The Mentor never activates until the user has
Sources/OneWeave/InvisibleMentor.swift:39:    public let citedReflectionID: UUID?    // the source quest/echo/echo id
Sources/OneWeave/InvisibleMentor.swift:40:    public let citedReflectionExcerpt: String?  // first 240 chars of the source
Sources/OneWeave/InvisibleMentor.swift:47:        citedReflectionID: UUID? = nil,
Sources/OneWeave/InvisibleMentor.swift:48:        citedReflectionExcerpt: String? = nil,
Sources/OneWeave/InvisibleMentor.swift:54:        self.citedReflectionID = citedReflectionID
Sources/OneWeave/InvisibleMentor.swift:55:        self.citedReflectionExcerpt = citedReflectionExcerpt
Sources/OneWeave/InvisibleMentor.swift:87:    public struct ReflectionSeed {
Sources/OneWeave/InvisibleMentor.swift:102:    public let reflections: [ReflectionSeed]
Sources/OneWeave/InvisibleMentor.swift:105:    public let completedQuestCount: Int
Sources/OneWeave/InvisibleMentor.swift:109:        reflections: [ReflectionSeed],
Sources/OneWeave/InvisibleMentor.swift:112:        completedQuestCount: Int,
Sources/OneWeave/InvisibleMentor.swift:118:        self.completedQuestCount = completedQuestCount
Sources/OneWeave/InvisibleMentor.swift:133:    public static let minimumReflections = 1
Sources/OneWeave/InvisibleMentor.swift:143:        // Reflection gate: dormant until the user has at least one reflection.
Sources/OneWeave/InvisibleMentor.swift:144:        guard input.reflections.count >= minimumReflections else {
Sources/OneWeave/InvisibleMentor.swift:188:                citedReflectionID: seed.id,
Sources/OneWeave/InvisibleMentor.swift:189:                citedReflectionExcerpt: String(seed.text.prefix(240)),
Sources/OneWeave/InvisibleMentor.swift:212:        // Reflections come from LifeEntity.summary text on .task / .concept /
Sources/OneWeave/InvisibleMentor.swift:214:        // whose `isUserReflection == true` (Nemotron #39). This prevents
Sources/OneWeave/InvisibleMentor.swift:218:        var seeds: [MentorInput.ReflectionSeed] = []
Sources/OneWeave/InvisibleMentor.swift:220:            guard e.isUserReflection else { continue }
Sources/OneWeave/InvisibleMentor.swift:253:            completedQuestCount: context.completedQuestCount,
Sources/OneWeave/InvisibleMentor.swift:265:        seed: MentorInput.ReflectionSeed,
Sources/OneWeave/MentorEchoBridge.swift:10://  from a real `SacredEchoStore` query. Without this bridge, the Mentor's
Sources/OneWeave/MentorEchoBridge.swift:15://    1. Decoupled. The bridge lives in its own file — SacredEcho stays
Sources/OneWeave/MentorEchoBridge.swift:24://    4. Reflection-only. The plaintext is sourced only from `SacredEchoCipher.open`
Sources/OneWeave/MentorEchoBridge.swift:34://    - Any state mutation. Opening an echo is owned by `SacredEchoStore.open`.
Sources/OneWeave/MentorEchoBridge.swift:121:    ///   - now: Override for tests. Defaults to SacredEcho.now() so the
Sources/OneWeave/MentorEchoBridge.swift:128:        from echoes: [SacredEcho],
Sources/OneWeave/MentorEchoBridge.swift:132:        let clock = now ?? SacredEcho.now()
Sources/OneWeave/MentorEchoBridge.swift:135:        let opened: [SacredEcho] = echoes.filter { echo in
Sources/OneWeave/MentorEchoBridge.swift:151:            guard let plaintext = try? SacredEchoCipher.open(
Sources/OneWeave/MentorEchoBridge.swift:185:    /// pipeline by constructing `SacredEcho` instances directly.
Sources/OneWeave/MentorEchoBridge.swift:192:        let descriptor = FetchDescriptor<SacredEcho>(
Sources/OneWeave/MentorEchoBridge.swift:193:            predicate: #Predicate<SacredEcho> { echo in
Sources/OneWeave/MentorEchoBridge.swift:197:            sortBy: [SortDescriptor(\SacredEcho.openedAt, order: .reverse)]
Sources/OneWeave/MentorEchoBridge.swift:199:        let echoes: [SacredEcho]
Sources/OneWeave/MentorEchoBridge.swift:302:            citedReflectionID: seed.id,
Sources/OneWeave/MentorEchoBridge.swift:303:            citedReflectionExcerpt: excerpt,
Sources/OneWeave/ThreadDetailView.swift:10:// Cross-wired to LifeContext, QuestService, TimelineService, emits for ripples.
Sources/OneWeave/ThreadDetailView.swift:17:    @Query private var allQuests: [WeaveQuest]
Sources/OneWeave/ThreadDetailView.swift:23:    @State private var showReflection = false
Sources/OneWeave/ThreadDetailView.swift:24:    @State private var selectedQuest: WeaveQuest?
Sources/OneWeave/ThreadDetailView.swift:39:    private var activeThreadQuests: [WeaveQuest] {
Sources/OneWeave/ThreadDetailView.swift:41:        // Support both persisted WeaveQuest and active UUIDs (handles demo/partial persistence)
Sources/OneWeave/ThreadDetailView.swift:42:        let byId = allQuests.filter { ctx.activeQuests.contains($0.id) && $0.domains.contains(threadName) }
Sources/OneWeave/ThreadDetailView.swift:45:        return allQuests.filter { $0.domains.contains(threadName) && $0.status != .completed }.prefix(3).map { $0 }
Sources/OneWeave/ThreadDetailView.swift:121:                        // === Active Quests List for this thread ===
Sources/OneWeave/ThreadDetailView.swift:124:                                Text("Active Weaves (Quests) for (threadName)")
Sources/OneWeave/ThreadDetailView.swift:127:                                if !activeThreadQuests.isEmpty {
Sources/OneWeave/ThreadDetailView.swift:128:                                    Text("(activeThreadQuests.count) active")
Sources/OneWeave/ThreadDetailView.swift:134:                            if activeThreadQuests.isEmpty {
Sources/OneWeave/ThreadDetailView.swift:140:                                ForEach(activeThreadQuests) { quest in
Sources/OneWeave/ThreadDetailView.swift:141:                                    QuestCard(quest: quest, thread: threadName) {
Sources/OneWeave/ThreadDetailView.swift:142:                                        selectedQuest = quest
Sources/OneWeave/ThreadDetailView.swift:144:                                        showReflection = true
Sources/OneWeave/ThreadDetailView.swift:172:                                    SuggestedQuestRow(quest: quest) {
Sources/OneWeave/ThreadDetailView.swift:173:                                        acceptQuestSuggestion(quest, in: ctx)
Sources/OneWeave/ThreadDetailView.swift:281:            .sheet(isPresented: $showReflection) {
Sources/OneWeave/ThreadDetailView.swift:282:                if let quest = selectedQuest, let ctx = context {
Sources/OneWeave/ThreadDetailView.swift:284:                        Text("Reflection Gate — Full Award")
Sources/OneWeave/ThreadDetailView.swift:303:                        Text("Reflection required for full essence + mastery tick. Be specific about the IRL action and insight.")
Sources/OneWeave/ThreadDetailView.swift:309:                                showReflection = false
Sources/OneWeave/ThreadDetailView.swift:314:                            Button("Submit Reflection & Complete") {
Sources/OneWeave/ThreadDetailView.swift:315:                                submitReflection(for: quest, ctx: ctx)
Sources/OneWeave/ThreadDetailView.swift:380:    private func generateThreadSuggestions(context ctx: LifeContext) -> [WeaveQuest] {
Sources/OneWeave/ThreadDetailView.swift:381:        let allSug = QuestService.shared.generateSuggestedQuests(from: ctx, recentEvents: Array(allEvents.prefix(10)))
Sources/OneWeave/ThreadDetailView.swift:388:    private func acceptQuestSuggestion(_ quest: WeaveQuest, in ctx: LifeContext) {
Sources/OneWeave/ThreadDetailView.swift:390:        if !allQuests.contains(where: { $0.id == quest.id }) {
Sources/OneWeave/ThreadDetailView.swift:393:        if !ctx.activeQuests.contains(quest.id) {
Sources/OneWeave/ThreadDetailView.swift:394:            ctx.activeQuests.append(quest.id)
Sources/OneWeave/ThreadDetailView.swift:409:    private func submitReflection(for quest: WeaveQuest, ctx: LifeContext) {
Sources/OneWeave/ThreadDetailView.swift:413:        let qs = QuestService.shared
Sources/OneWeave/ThreadDetailView.swift:414:        qs.completeWithReflection(questId: quest.id, reflection: trimmed, context: ctx, modelContext: modelContext)
Sources/OneWeave/ThreadDetailView.swift:438:        feedback = "✧ Reflection complete! +Essence • Mastery tick in (threadName) • Ripple sent."
Sources/OneWeave/ThreadDetailView.swift:439:        showReflection = false
Sources/OneWeave/ThreadDetailView.swift:441:        selectedQuest = nil
Sources/OneWeave/ThreadDetailView.swift:533:            let active = activeThreadQuests.map { $0.title }.joined(separator: "; ")
Sources/OneWeave/ThreadDetailView.swift:534:            gamif = "\n\nMastery Tier: (tier) ((tierName(for: tier)))\nActive Quests: (active.isEmpty ? "none" : active)\nStreak: (ctx.globalWeaveStreak) • Essence: (Int(ctx.weaveEssence))"
Sources/OneWeave/ThreadDetailView.swift:576:struct QuestCard: View {
Sources/OneWeave/ThreadDetailView.swift:577:    let quest: WeaveQuest
Sources/OneWeave/ThreadDetailView.swift:610:struct SuggestedQuestRow: View {
Sources/OneWeave/ThreadDetailView.swift:611:    let quest: WeaveQuest
Sources/OneWeave/ThreadDetailView.swift:675:        .modelContainer(for: [LifeContext.self, TimelineEvent.self, WeaveQuest.self])
Sources/OneWeave/CommandPalette.swift:7://  Creates quests (QuestService), logs weaves (TimelineService), changes season,
Sources/OneWeave/CommandPalette.swift:12://  - Quest creation routes through QuestService (which enforces reflection gate).
Sources/OneWeave/CommandPalette.swift:28:    @State private var pendingReflection: String = ""
Sources/OneWeave/CommandPalette.swift:59:            // Reflection sheet (only for actions that need a note before commit).
Sources/OneWeave/CommandPalette.swift:62:                    Text("Reflection required to commit \"\(action.title)\"")
Sources/OneWeave/CommandPalette.swift:64:                    TextField("Optional reflection note", text: $pendingReflection, axis: .vertical)
Sources/OneWeave/CommandPalette.swift:70:                            pendingReflection = ""
Sources/OneWeave/CommandPalette.swift:73:                            commitPending(action: action, reflection: pendingReflection)
Sources/OneWeave/CommandPalette.swift:75:                            pendingReflection = ""
Sources/OneWeave/CommandPalette.swift:77:                        .disabled(pendingReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
Sources/OneWeave/CommandPalette.swift:98:            pendingAction = PendingCommandAction(kind: .createQuest, title: trimmed, body: trimmed)
Sources/OneWeave/CommandPalette.swift:100:                title: "Quest queued",
Sources/OneWeave/CommandPalette.swift:101:                detail: "Reflection required before commit."
Sources/OneWeave/CommandPalette.swift:107:                detail: "Reflection required; essence only awarded after commit."
Sources/OneWeave/CommandPalette.swift:111:                ctx.changeSeason(to: trimmed)
Sources/OneWeave/CommandPalette.swift:112:                results.append(CommandResult(title: "Season change requested", detail: "Reflection gate will prompt next interaction."))
Sources/OneWeave/CommandPalette.swift:132:        case .createQuest:
Sources/OneWeave/CommandPalette.swift:133:            // Real: route to QuestService (which enforces its own reflection gate).
Sources/OneWeave/CommandPalette.swift:134:            if let svc = QuestService.shared {
Sources/OneWeave/CommandPalette.swift:135:                _ = svc.generateSuggestedQuests(from: ctx, recentEvents: [])
Sources/OneWeave/CommandPalette.swift:138:                    title: "Quest created",
Sources/OneWeave/CommandPalette.swift:142:                results.append(CommandResult(title: "QuestService unavailable", detail: "Try again after app loads."))
Sources/OneWeave/CommandPalette.swift:169:    enum CommandKind { case createQuest, logWeave }
Sources/OneWeave/ResonanceOracleSheet.swift:89:                        Text("Reflection required to commit.")
Sources/OneWeave/ResonanceOracleSheet.swift:96:                            ResonanceOracle.commitWeave(from: s, into: context, userReflection: reflection, modelContext: modelContext)
Sources/OneWeave/ResonanceOracleSheet.swift:97:                            committedMessage = "Weave committed. Reflection stored with entity."
Sources/OneWeave/OneWeaveApp.swift:17:                    WeaveQuest.self,
Sources/OneWeave/OneWeaveApp.swift:25:                    DataLeashSettingsRecord.self,
Sources/OneWeave/OneWeaveApp.swift:27:                    SacredEcho.self
Sources/OneWeave/OneWeaveApp.swift:48:                        case "QuestsView":
Sources/OneWeave/OneWeaveApp.swift:49:                            QuestsView()
Sources/OneWeave/OneWeaveApp.swift:106:        let leash: DataLeashState = (try? modelContext.fetch(
Sources/OneWeave/OneWeaveApp.swift:107:            FetchDescriptor<DataLeashSettingsRecord>()
Sources/OneWeave/OneWeaveApp.swift:109:        let echoes: [SacredEcho] = (try? modelContext.fetch(
Sources/OneWeave/OneWeaveApp.swift:110:            FetchDescriptor<SacredEcho>()
Sources/OneWeave/OneWeaveApp.swift:112:        let quests: [WeaveQuest] = (try? modelContext.fetch(
Sources/OneWeave/OneWeaveApp.swift:113:            FetchDescriptor<WeaveQuest>(
Sources/OneWeave/OneWeaveApp.swift:136:            WeaveQuest.self,
Sources/OneWeave/OneWeaveApp.swift:143:            DataLeashSettingsRecord.self,
Sources/OneWeave/OneWeaveApp.swift:144:            SacredEcho.self
Sources/OneWeave/LifeGraph.swift:6:// Extends existing OneWeave Threads/TimelineEvent/WeaveQuest without replacement.
Sources/OneWeave/LifeGraph.swift:33:    // as `[String: String]` to match SacredEcho + BodyThread conventions.
Sources/OneWeave/LifeGraph.swift:37:    // Mentor only surfaces entities with `isUserReflection == true` so that
Sources/OneWeave/LifeGraph.swift:39:    var isUserReflection: Bool = false
Sources/OneWeave/LifeGraph.swift:114:            entity.isUserReflection = true
Sources/OneWeave/LifeGraph.swift:121:    // From WeaveQuest (Task). Honours Nemotron #8: derive essence from quest.baseEssence
Sources/OneWeave/LifeGraph.swift:122:    // (and gate on completion). Reflection is required for the entity to be created from
Sources/OneWeave/LifeGraph.swift:124:    static func fromQuest(_ quest: WeaveQuest) -> LifeEntity {
Sources/OneWeave/LifeGraph.swift:136:        entity.isUserReflection = (quest.reflectionNote?.isEmpty == false)
Sources/OneWeave/SacredEcho.swift:2://  SacredEcho.swift
Sources/OneWeave/SacredEcho.swift:14://    2. Reflection-gated — empty payload is refused at seal time.
Sources/OneWeave/SacredEcho.swift:65:    case emptyReflection
Sources/OneWeave/SacredEcho.swift:77:        case .emptyReflection:
Sources/OneWeave/SacredEcho.swift:100:// MARK: - SacredEcho SwiftData model
Sources/OneWeave/SacredEcho.swift:103:public final class SacredEcho {
Sources/OneWeave/SacredEcho.swift:153:        self.createdAt = SacredEcho.now()
Sources/OneWeave/SacredEcho.swift:171:        let now = SacredEcho.now()
Sources/OneWeave/SacredEcho.swift:186:        let n = now ?? SacredEcho.now()
Sources/OneWeave/SacredEcho.swift:222:// MARK: - SacredEchoCipher (envelope encryption)
Sources/OneWeave/SacredEcho.swift:228://   2. Each SacredEcho derives its own per-echo key via HKDF over (vaultSeed || echo.id).
Sources/OneWeave/SacredEcho.swift:229://   3. Reflection is sealed with AES-GCM under the per-echo key.
Sources/OneWeave/SacredEcho.swift:236:public enum SacredEchoCipher {
Sources/OneWeave/SacredEcho.swift:273:        let info = "SacredEcho.\(echoID.uuidString)".data(using: .utf8)!
Sources/OneWeave/SacredEcho.swift:341:            fatalError("[SacredEcho] Cannot obtain secure random bytes for nonce generation")
Sources/OneWeave/SacredEcho.swift:353:            fatalError("[SacredEcho] Cannot open /dev/urandom")
Sources/OneWeave/SacredEcho.swift:414:// MARK: - SacredEchoStore (open/seal/hand-deliver API)
Sources/OneWeave/SacredEcho.swift:426:public enum SacredEchoStore {
Sources/OneWeave/SacredEcho.swift:428:    /// Seal a new Sacred Echo. Reflection is required (gate). Unlock date must
Sources/OneWeave/SacredEcho.swift:440:    ) throws -> SacredEcho {
Sources/OneWeave/SacredEcho.swift:442:        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
Sources/OneWeave/SacredEcho.swift:445:        guard !trimmedReflection.isEmpty else { throw EchoError.emptyReflection }
Sources/OneWeave/SacredEcho.swift:446:        guard unlockAt > SacredEcho.now() else { throw EchoError.unlockDateInPast }
Sources/OneWeave/SacredEcho.swift:457:        let (ciphertext, nonce, tag) = try SacredEchoCipher.seal(
Sources/OneWeave/SacredEcho.swift:458:            plaintext: trimmedReflection,
Sources/OneWeave/SacredEcho.swift:461:        let echo = SacredEcho(
Sources/OneWeave/SacredEcho.swift:471:                "created_iso": ISO8601DateFormatter().string(from: SacredEcho.now())
Sources/OneWeave/SacredEcho.swift:510:    /// Returns (plaintextReflection, decree) so the caller can present both.
Sources/OneWeave/SacredEcho.swift:514:        _ echo: SacredEcho,
Sources/OneWeave/SacredEcho.swift:517:        let now = SacredEcho.now()
Sources/OneWeave/SacredEcho.swift:533:        let reflection = try SacredEchoCipher.open(
Sources/OneWeave/SacredEcho.swift:553:    /// Weave Circle (validated up-front). Reflection-gated: an echo that has
Sources/OneWeave/SacredEcho.swift:559:        _ echo: SacredEcho,
Sources/OneWeave/SacredEcho.swift:560:        deliveryReflection: String,
Sources/OneWeave/SacredEcho.swift:564:        let trimmed = deliveryReflection.trimmingCharacters(in: .whitespacesAndNewlines)
Sources/OneWeave/SacredEcho.swift:565:        guard !trimmed.isEmpty else { throw EchoError.emptyReflection }
Sources/OneWeave/SacredEcho.swift:584:        // SacredEchoCipher so the promise holds.
Sources/OneWeave/SacredEcho.swift:586:        echo.attributes["delivered_iso"] = ISO8601DateFormatter().string(from: SacredEcho.now())
Sources/OneWeave/SacredEcho.swift:608:            summary: "Hand-delivered on \(ISO8601DateFormatter().string(from: SacredEcho.now())).",
Sources/OneWeave/SacredEcho.swift:624:    /// Release an echo without opening. Reflection required to ensure the
Sources/OneWeave/SacredEcho.swift:627:        _ echo: SacredEcho,
Sources/OneWeave/SacredEcho.swift:628:        releaseReflection: String,
Sources/OneWeave/SacredEcho.swift:631:        let trimmed = releaseReflection.trimmingCharacters(in: .whitespacesAndNewlines)
Sources/OneWeave/SacredEcho.swift:632:        guard !trimmed.isEmpty else { throw EchoError.emptyReflection }
Sources/OneWeave/SacredEcho.swift:637:        echo.attributes["released_iso"] = ISO8601DateFormatter().string(from: SacredEcho.now())
Sources/OneWeave/WeaveQuest.swift:5:final class WeaveQuest {
Sources/OneWeave/WeaveQuest.swift:11:    var status: QuestStatus = QuestStatus.pending
Sources/OneWeave/WeaveQuest.swift:28:    enum QuestStatus: String, Codable, CaseIterable {
Sources/OneWeave/WeaveQuest.swift:36:extension WeaveQuest {
Sources/OneWeave/SchemaMigrationPlan.swift:22://    5. WeaveQuest         (gamification quest)
Sources/OneWeave/SchemaMigrationPlan.swift:23://    6. DataLeashSettingsRecord  (privacy toggles)
Sources/OneWeave/SchemaMigrationPlan.swift:24://    7. SacredEcho         (encrypted time capsule)
Sources/OneWeave/SchemaMigrationPlan.swift:32://    V2:           adds isUserReflection on LifeEntity (Nemotron #39 fix)
Sources/OneWeave/SchemaMigrationPlan.swift:70:         TimelineEvent.self, WeaveQuest.self, DataLeashSettingsRecord.self,
Sources/OneWeave/SchemaMigrationPlan.swift:71:         SacredEcho.self, BasicSelfThread.self, CareKinThread.self,
Sources/OneWeave/SchemaMigrationPlan.swift:81:        public var completedQuestCount: Int
Sources/OneWeave/SchemaMigrationPlan.swift:82:        public var lastReflectionAt: Date?
Sources/OneWeave/SchemaMigrationPlan.swift:88:        public var quests: [WeaveQuest]
Sources/OneWeave/SchemaMigrationPlan.swift:95:            self.completedQuestCount = 0; self.lastReflectionAt = nil
Sources/OneWeave/SchemaMigrationPlan.swift:111:        public var isUserReflection: Bool
Sources/OneWeave/SchemaMigrationPlan.swift:125:            self.isUserReflection = false; self.harmonyImpact = 0.0
Sources/OneWeave/SchemaMigrationPlan.swift:157:    public final class WeaveQuest {
Sources/OneWeave/SchemaMigrationPlan.swift:170:    public final class DataLeashSettingsRecord {
Sources/OneWeave/SchemaMigrationPlan.swift:182:    public final class SacredEcho {
Sources/OneWeave/SchemaMigrationPlan.swift:248:// MARK: - Schema V2 (adds isUserReflection + lastUpdated)
Sources/OneWeave/SchemaMigrationPlan.swift:261:    // Models identical to V1 except LifeEntity has isUserReflection, lastUpdated.
Sources/OneWeave/SchemaMigrationPlan.swift:283:        public var isUserReflection: Bool
Sources/OneWeave/SchemaMigrationPlan.swift:297:            self.isUserReflection = false; self.harmonyImpact = 0.0
Sources/OneWeave/QuestService.swift:4:// QuestService: Generates, manages quests per 002-gamification spec.
Sources/OneWeave/QuestService.swift:6:final class QuestService {
Sources/OneWeave/QuestService.swift:7:    static let shared = QuestService()
Sources/OneWeave/QuestService.swift:12:    func generateSuggestedQuests(from context: LifeContext, recentEvents: [TimelineEvent]) -> [WeaveQuest] {
Sources/OneWeave/QuestService.swift:13:        var quests: [WeaveQuest] = []
Sources/OneWeave/QuestService.swift:16:        quests.append(WeaveQuest(
Sources/OneWeave/QuestService.swift:26:        quests.append(WeaveQuest(
Sources/OneWeave/QuestService.swift:36:        quests.append(WeaveQuest(
Sources/OneWeave/QuestService.swift:46:        quests.append(WeaveQuest(
Sources/OneWeave/QuestService.swift:57:            quests.append(WeaveQuest(
Sources/OneWeave/QuestService.swift:69:            quests.append(WeaveQuest(
Sources/OneWeave/QuestService.swift:83:    func acceptQuest(_ quest: WeaveQuest, context: LifeContext, modelContext: ModelContext) {
Sources/OneWeave/QuestService.swift:84:        context.activeQuests.append(quest.id)
Sources/OneWeave/QuestService.swift:85:    let qs = (try? modelContext.fetch(FetchDescriptor<WeaveQuest>())) ?? []
Sources/OneWeave/QuestService.swift:86:    context.pushSnapshotToWidgets(from: qs)
Sources/OneWeave/QuestService.swift:91:    func completeWithReflection(questId: UUID, reflection: String, context: LifeContext, modelContext: ModelContext) {
Sources/OneWeave/QuestService.swift:92:        context.completeQuest(questId, reflection: reflection, context: modelContext)
Sources/OneWeave/QuestService.swift:93:    let qs = (try? modelContext.fetch(FetchDescriptor<WeaveQuest>())) ?? []
Sources/OneWeave/QuestService.swift:94:    context.pushSnapshotToWidgets(from: qs)
Sources/OneWeave/QuestService.swift:98:    // Custom quest forge (Phase 2): spend Essence (or future premium) to create user-defined WeaveQuest.
Sources/OneWeave/QuestService.swift:100:    func forgeCustomQuest(title: String, description: String, domains: [String], estimatedIRLMinutes: Int, baseEssence: Int, context: LifeContext) -> WeaveQuest? {
Sources/OneWeave/QuestService.swift:107:        let forged = WeaveQuest(
Sources/OneWeave/PrivacyAudit.md:9:- Reflection gates enforce anti-addiction (full reward requires IRL note).
Sources/OneWeave/PrivacyAudit.md:14:- CompassView.swift, LifeContext.swift, QuestService.swift, etc. (10+ files).
Sources/OneWeave/PrivacyAudit.md:26:## Code Review (Grep + Manual - Gamification Layer Focus)
Sources/OneWeave/PrivacyAudit.md:30:  - CompassView.swift:5: "// Privacy: all gamification (essence, mastery, quests, loom state) is local SwiftData only. // No network, no external calls, no training. Export/clear works via Settings. Reflection gates anti-addiction."
Sources/OneWeave/PrivacyAudit.md:33:  - QuestService.swift:5: "// Local-only, context-aware, IRL-first, anti-addictive (reflection required for full reward)."
Sources/OneWeave/PrivacyAudit.md:40:- All core gamif state in @Model classes or extensions persisted via SwiftData (LifeContext aggregates essence, masteryTiers, streaks, graceDaysUsed, activeQuests, completedQuestCount, harmonyScore, essenceLedger).
Sources/OneWeave/PrivacyAudit.md:48:- All logic: rule-based on TimelineEvent + LifeContext (awardEssenceForEvent, updateHarmonyAndStreak, completeQuest, generateSuggestedQuests, updateMasteryFromEvent) + SwiftData.
Sources/OneWeave/PrivacyAudit.md:49:- QuestService, TimelineService, InsightGenerator: purely on-device.
Sources/OneWeave/PrivacyAudit.md:50:- Confirmed via graphify: gamif communities/hubs (e.g. Community 5-8,16,22, QuestService/LifeContext/WeaveQuest nodes) have zero external edges/paths. God nodes: BasicSelfThread, SwiftData, CareKinThread, LifeContext (all local). 589 nodes total, "no external paths found in gamif code".
Sources/OneWeave/PrivacyAudit.md:61:- No-training/privacy prefixes/comments on new gamif models/services (LifeContext, QuestService, WeaveQuest, threads).
Sources/OneWeave/PrivacyAudit.md:62:- Data stays in user-controlled SwiftData container (no CloudKit default).
Sources/OneWeave/PrivacyAudit.md:66:## Anti-Addiction (Reflection Gates + Grace)
Sources/OneWeave/PrivacyAudit.md:68:**Reflection Gates (IRL-first, full reward requires note):**
Sources/OneWeave/PrivacyAudit.md:69:- WeaveQuest.swift: var reflectionNote: String? ; QuestStatus includes "reflected".
Sources/OneWeave/PrivacyAudit.md:70:- QuestService.swift: generateSuggestedQuests includes validationHints e.g. "Close app. Make it happen IRL.", "Do this IRL now. Step away from screen.", "Grace for streak. Rest first.", "Real action: cancel or redirect...".
Sources/OneWeave/PrivacyAudit.md:71:  - completeWithReflection(questId, reflection: String, ...) delegates to context.
Sources/OneWeave/PrivacyAudit.md:74:  func completeQuest(_ questId: UUID, reflection: String, context: ModelContext) {
Sources/OneWeave/PrivacyAudit.md:82:- CompassView.swift:27-32 (state for gate), 285+ Quests section, 407:
Sources/OneWeave/PrivacyAudit.md:83:  - Reflection sheet: Text("Your reflection (required for full award)"), TextEditor, button disabled if reflectionText.trimming... .isEmpty
Sources/OneWeave/PrivacyAudit.md:84:  - On complete: qs.completeWithReflection(...) only after non-empty note.
Sources/OneWeave/PrivacyAudit.md:105:  - Restoration quests auto-suggested in lowEnergy (QuestService: "Restorative micro-rest", "Grace for streak. Rest first.").
Sources/OneWeave/PrivacyAudit.md:114:- **WeaveQuest persistence**: @Model defined + used in QuestService/Compass/Prototype (in-memory arrays, UUID refs in LifeContext.activeQuests). **But NOT registered in modelContainer** in OneWeaveApp.swift:11-18 or prototype preview (only LifeContext, TimelineEvent, 4 Threads). Quests generated fresh each time (QuestService); "In full: persist quest to SwiftData" comment in QuestService:85. Risk: quests lost on app restart; activeQuests UUIDs may dangle. (Priority for full Phase 7.)
Sources/OneWeave/PrivacyAudit.md:116:- **Clear completeness**: SettingsView.swift:88 clearAllData() deletes LifeContext, TimelineEvent, 4 Threads. **No delete for WeaveQuest** (or future models). activeQuests refs in LifeContext not cleaned if quests persisted. No user confirmation beyond alert; irreversible.
Sources/OneWeave/PrivacyAudit.md:117:- **Reflection bypass**: UI gate strong (disabled button), but direct LifeContext.completeQuest(questId, reflection: "") or service calls could award without meaningful note (no validation beyond non-empty in flow). Reflection stored but not deeply analyzed (local only).
Sources/OneWeave/PrivacyAudit.md:119:- **Metrics privacy**: Internal only in LifeContext (completedQuestCount, harmonyScore, essenceLedger capped@20, eventCount, activeQuests, grace counters). Surfaced in Prototype HUD, Compass, MasteryMap (counts, % harmony, streak). No % reflection calc explicit yet; "disengagement" via notes stub. **No external/telemetry**; private on-device. Good, but incomplete surface (Phase 7 stub).
Sources/OneWeave/PrivacyAudit.md:121:- **Container/Schema**: Gamif fields added to LifeContext post-initial; SwiftData migrations not explicit in code (may need for prod). activeQuests [UUID] but quests not @Model persisted.
Sources/OneWeave/PrivacyAudit.md:123:- **Graphify confirmation**: 589 nodes/880 edges; gamif isolated in local communities (no external imports/edges in Quest/LifeContext paths). "INFERRED" edges are internal.
Sources/OneWeave/PrivacyAudit.md:124:- **Other**: Quests not queryable via @Query yet (state-driven); full cascade from threads to quests via TimelineService ok. LowEnergy restoration integrated. Prototype Phase 7 notes explicitly call out verification of these.
Sources/OneWeave/PrivacyAudit.md:129:- Local SwiftData: Yes (core); gaps in WeaveQuest registration/persistence noted.
Sources/OneWeave/PrivacyAudit.md:132:- Reflection for addiction: Fully gated in flow + logic.
Sources/OneWeave/PrivacyAudit.md:135:- Anti-addiction: Reflection + grace implemented as specified.
Sources/OneWeave/PrivacyAudit.md:137:Re-audit after adding WeaveQuest to containers + full export.
Sources/OneWeave/DecisionLog.swift:29://      isUserReflection-equivalent (we use isPrivate + isUserReflection on
Sources/OneWeave/DecisionLog.swift:35://    1. Reflection-gated. Recording a decision requires a non-empty reasoning
Sources/OneWeave/DecisionLog.swift:144:    /// Record a new decision. Reflection-gated: reasoning must be non-empty.
Sources/OneWeave/DecisionLog.swift:179:    /// Update a decision with the actual outcome. Reflection-gated:
Sources/OneWeave/DecisionLog.swift:231:    ) -> MentorInput.ReflectionSeed {
Sources/OneWeave/DecisionLog.swift:237:        return MentorInput.ReflectionSeed(
Sources/OneWeave/OneWeaveAPI.swift:50:    //      Graph node. Has isUserReflection flag (Nemotron #39 fix).
Sources/OneWeave/OneWeaveAPI.swift:59:    //    - `public final class WeaveQuest` (SwiftData @Model) — completion
Sources/OneWeave/OneWeaveAPI.swift:64:    // 2. Privacy + Data Leash — see Sources/OneWeave/DataLeashSettings.swift
Sources/OneWeave/OneWeaveAPI.swift:67:    //    - `public final class DataLeashSettingsRecord` (SwiftData @Model)
Sources/OneWeave/OneWeaveAPI.swift:68:    //    - `public enum DataLeashPolicy` — currentLeash(in: ModelContext),
Sources/OneWeave/OneWeaveAPI.swift:73:    // 3. Sacred Echo Vault — see Sources/OneWeave/SacredEcho.swift
Sources/OneWeave/OneWeaveAPI.swift:74:    //    - `public final class SacredEcho` (SwiftData @Model)
Sources/OneWeave/OneWeaveAPI.swift:79:    //    - `public enum EchoError` — emptyReflection, notYetUnlocked,
Sources/OneWeave/OneWeaveAPI.swift:81:    //    - `public enum SacredEchoCipher` — vaultSeed(), perEchoKey(),
Sources/OneWeave/OneWeaveAPI.swift:84:    //    - `public enum SacredEchoStore` (@MainActor) — seal(), open(),
Sources/OneWeave/OneWeaveAPI.swift:93:    //      Reflection-gated: dormant below minimumReflections.
Sources/OneWeave/OneWeaveAPI.swift:114:    //      Reflection gate: pendingIntegrations drained only after user
Sources/OneWeave/OneWeaveAPI.swift:120:    //      to strictest (only completedQuestCount + currentHarmonyScore).
Sources/OneWeave/OneWeaveAPI.swift:121:    //    - `public enum FamilyPodLimits` — maxMembers=6, minExitReflection=20,
Sources/OneWeave/OneWeaveAPI.swift:133:    //      publicBundle, fullBundle. permitsReflections + permitsEchoPlaintext.
Sources/OneWeave/OneWeaveAPI.swift:134:    //    - `public enum PortableExportPolicy` — fullBundleMinReflection=30,
Sources/OneWeave/OneWeaveAPI.swift:156:    //      SacredEcho vault seed for at-rest persistence.
Sources/OneWeave/OneWeaveAPI.swift:182:    //      renderer. Breath rate ∝ 1/timeOfDay; palette ∝ currentSeason.
Sources/OneWeave/OneWeaveAPI.swift:188:        "WeaveQuest", "DataLeashSettingsRecord", "SacredEcho",
Sources/OneWeave/OneWeaveAPI.swift:209:        "Sources/OneWeave/WeaveQuest.swift",
Sources/OneWeave/OneWeaveAPI.swift:214:        "Sources/OneWeave/DataLeashSettings.swift",
Sources/OneWeave/OneWeaveAPI.swift:215:        "Sources/OneWeave/SacredEcho.swift",
Sources/OneWeave/AppLifecycleCoordinator.swift:18://    - Encrypted with the same SacredEchoCipher vault key (AES-256-GCM with
Sources/OneWeave/AppLifecycleCoordinator.swift:52:    public var echoes: [SacredEchoDTO]
Sources/OneWeave/AppLifecycleCoordinator.swift:56:    public var completedQuestCount: Int
Sources/OneWeave/AppLifecycleCoordinator.swift:63:        echoes: [SacredEchoDTO],
Sources/OneWeave/AppLifecycleCoordinator.swift:67:        completedQuestCount: Int
Sources/OneWeave/AppLifecycleCoordinator.swift:77:        self.completedQuestCount = completedQuestCount
Sources/OneWeave/AppLifecycleCoordinator.swift:107:public struct SacredEchoDTO: Codable, Equatable {
Sources/OneWeave/AppLifecycleCoordinator.swift:182:        echoes: [SacredEcho] = []
Sources/OneWeave/AppLifecycleCoordinator.swift:210:        let echoDTOs: [SacredEchoDTO] = echoes.map { e in
Sources/OneWeave/AppLifecycleCoordinator.swift:211:            SacredEchoDTO(
Sources/OneWeave/AppLifecycleCoordinator.swift:233:            completedQuestCount: context.completedQuestCount
Sources/OneWeave/AppLifecycleCoordinator.swift:249:        let seed = SacredEchoCipher.vaultSeed()
Sources/OneWeave/AppLifecycleCoordinator.swift:250:        let key = SacredEchoCipher.perEchoKey(for: envelopeKeyID, seed: seed)
Sources/OneWeave/AppLifecycleCoordinator.swift:268:        let seed = SacredEchoCipher.vaultSeed()
Sources/OneWeave/AppLifecycleCoordinator.swift:269:        let key = SacredEchoCipher.perEchoKey(for: envelopeKeyID, seed: seed)
Sources/OneWeave/AppLifecycleCoordinator.swift:395:        echoes: [SacredEcho] = [],
Sources/OneWeave/AppLifecycleCoordinator.swift:396:        quests: [WeaveQuest] = [],
Sources/OneWeave/AppLifecycleCoordinator.swift:416:        context.pushSnapshotToWidgets(from: quests)
Sources/OneWeave/AppLifecycleCoordinator.swift:424:    /// Note (Claude cycle-24): `SacredEcho` is a class; no `inout` needed.
Sources/OneWeave/AppLifecycleCoordinator.swift:427:        echoes: [SacredEcho],
Sources/OneWeave/AppLifecycleCoordinator.swift:428:        leash: DataLeashState,
Sources/OneWeave/AppLifecycleCoordinator.swift:431:        // Re-evaluate echo states. The SacredEcho.state getter derives from
Sources/OneWeave/AppLifecycleCoordinator.swift:483:        echoes: [SacredEcho] = [],
Sources/OneWeave/AppLifecycleCoordinator.swift:484:        quests: [WeaveQuest] = [],
Sources/OneWeave/AppLifecycleCoordinator.swift:485:        leash: DataLeashState,
Sources/OneWeave/GraphInsightGenerator.swift:35:// - Reflection-gated awards still go through `applyInsight` — the cache only
Sources/OneWeave/GraphInsightGenerator.swift:69:    /// coherenceScore, completedQuestCount, masteryTiers, currentSeason,
Sources/OneWeave/GraphInsightGenerator.swift:79:        let completedQuestCount: Int
Sources/OneWeave/GraphInsightGenerator.swift:81:        let currentSeason: String
Sources/OneWeave/GraphInsightGenerator.swift:137:        // 1. Harmony vs Quest Completion (existing data + graph)
Sources/OneWeave/GraphInsightGenerator.swift:138:        let highHarmonyQuests = entities.filter { $0.type == .task && $0.harmonyImpact > 0.7 }.count
Sources/OneWeave/GraphInsightGenerator.swift:139:        if context.harmonyScore > 0.7 && context.completedQuestCount > 5 && highHarmonyQuests > 2 {
Sources/OneWeave/GraphInsightGenerator.swift:141:                title: "High Harmony + Quest Momentum",
Sources/OneWeave/GraphInsightGenerator.swift:165:        // 3. Seasonal + Energy Pattern (from current seasons + energyProfile)
Sources/OneWeave/GraphInsightGenerator.swift:166:        let season = context.currentSeason
Sources/OneWeave/GraphInsightGenerator.swift:235:                (Reflection required before any coherence is awarded.)
Sources/OneWeave/GraphInsightGenerator.swift:290:            print("[Insight] Reflection gate: essence not awarded for \"\(insight.title)\" without reflection.")
Sources/OneWeave/GraphInsightGenerator.swift:352:            completedQuestCount: context.completedQuestCount,
Sources/OneWeave/GraphInsightGenerator.swift:354:            currentSeason: context.currentSeason,
Sources/OneWeave/FamilyPod.swift:63:    public static let minExitReflectionChars: Int = 20
Sources/OneWeave/FamilyPod.swift:96:    case completedQuestCount       // e.g. "3 today"
Sources/OneWeave/FamilyPod.swift:106:    /// The default grants for a new pod. Strict: only completedQuestCount
Sources/OneWeave/FamilyPod.swift:109:        .completedQuestCount,
Sources/OneWeave/FamilyPod.swift:207:    public let completedQuestCount: Int?
Sources/OneWeave/FamilyPod.swift:219:        completedQuestCount: Int? = nil,
Sources/OneWeave/FamilyPod.swift:230:        self.completedQuestCount = completedQuestCount
Sources/OneWeave/FamilyPod.swift:261:    public let senderReflectionNote: String?    // NEVER user reflection text; optional one-line note like "had a good day"
Sources/OneWeave/FamilyPod.swift:267:        senderReflectionNote: String? = nil,
Sources/OneWeave/FamilyPod.swift:272:        self.senderReflectionNote = senderReflectionNote
Sources/OneWeave/FamilyPod.swift:296:        openedEchoes: [SacredEcho] = [],
Sources/OneWeave/FamilyPod.swift:305:        if pod.grants.contains(.completedQuestCount) {
Sources/OneWeave/FamilyPod.swift:306:            entry.completedQuestCount = context.completedQuestCount
Sources/OneWeave/FamilyPod.swift:315:            entry.currentStreak = context.completedQuestCount > 0 ? 1 : 0
Sources/OneWeave/FamilyPod.swift:339:            entry.seasonName = context.currentSeasonName
Sources/OneWeave/FamilyPod.swift:358:    case exitReflectionTooShort(min: Int, got: Int)
Sources/OneWeave/FamilyPod.swift:376:        case .exitReflectionTooShort(let min, let got):
Sources/OneWeave/FamilyPod.swift:475:    /// FamilyPodLimits.minExitReflectionChars. This protects against
Sources/OneWeave/FamilyPod.swift:480:        exitReflection: String
Sources/OneWeave/FamilyPod.swift:486:        let trimmed = exitReflection.trimmingCharacters(in: .whitespacesAndNewlines)
Sources/OneWeave/FamilyPod.swift:487:        guard trimmed.count >= FamilyPodLimits.minExitReflectionChars else {
Sources/OneWeave/FamilyPod.swift:488:            throw FamilyPodError.exitReflectionTooShort(
Sources/OneWeave/FamilyPod.swift:489:                min: FamilyPodLimits.minExitReflectionChars,
Sources/OneWeave/FamilyPod.swift:572:            completedQuestCount: pod.grants.contains(.completedQuestCount) ? entry.completedQuestCount : nil,
Sources/OneWeave/iOSServiceIntegrations.swift:84:    public static func importRecentEvents(into context: LifeContext, leash: DataLeashState, daysWindow: Int = 30) async -> [LifeEntity] {
Sources/OneWeave/iOSServiceIntegrations.swift:153:    public static func importContacts(into context: LifeContext, leash: DataLeashState) async -> [LifeEntity] {
Sources/OneWeave/iOSServiceIntegrations.swift:253:    public static func detectLowCoherence(leash: DataLeashState) async -> HealthThread {
Sources/OneWeave/iOSServiceIntegrations.swift:337:        leash: DataLeashState = .strictDefault
Sources/OneWeave/iOSServiceIntegrations.swift:362:        leash: DataLeashState = .strictDefault
Sources/OneWeave/iOSServiceIntegrations.swift:384:        leash: DataLeashState = .strictDefault
Sources/OneWeave/iOSServiceIntegrations.swift:387:        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
Sources/OneWeave/iOSServiceIntegrations.swift:389:        guard !trimmedReflection.isEmpty else { return nil }
Sources/OneWeave/iOSServiceIntegrations.swift:397:        \(trimmedReflection)
Sources/OneWeave/iOSServiceIntegrations.swift:413:        leash: DataLeashState = .strictDefault
Sources/OneWeave/iOSServiceIntegrations.swift:469:        leash: DataLeashState = .strictDefault
Sources/OneWeave/iOSServiceIntegrations.swift:478:        ## Reflection
Sources/OneWeave/iOSServiceIntegrations.swift:493:        leash: DataLeashState = .strictDefault
Sources/OneWeave/iOSServiceIntegrations.swift:496:        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
Sources/OneWeave/iOSServiceIntegrations.swift:498:        guard !trimmedReflection.isEmpty else { return nil }
Sources/OneWeave/iOSServiceIntegrations.swift:512:        \(trimmedReflection)
Sources/OneWeave/iOSServiceIntegrations.swift:525:        leash: DataLeashState = .strictDefault
Sources/OneWeave/iOSServiceIntegrations.swift:582:        leash: DataLeashState,
Sources/OneWeave/iOSServiceIntegrations.swift:664:    /// Create a new reminder from a WeaveQuest. Returns the created `EKReminder`
Sources/OneWeave/iOSServiceIntegrations.swift:666:    /// or leash blocks. Reflection-gated: caller must pass non-empty reflection.
Sources/OneWeave/iOSServiceIntegrations.swift:676:        leash: DataLeashState,
Sources/OneWeave/iOSServiceIntegrations.swift:679:        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
Sources/OneWeave/iOSServiceIntegrations.swift:680:        guard !trimmedReflection.isEmpty else {
Sources/OneWeave/iOSServiceIntegrations.swift:681:            print("[Reminders] Reflection gate: cannot create reminder without reflection.")
Sources/OneWeave/TimelineEvent.swift:40:// No external sync unless user opts into private CloudKit. No data sent for model training.
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:19:        let sampleQuests = [
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:20:            WeaveQuest(id: UUID(), title: "Call mom", domains: ["CareKin"], reflectionNote: "Felt good after"),
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:21:            WeaveQuest(id: UUID(), title: "Journal on purpose", domains: ["Meaning"], reflectionNote: nil)
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:31:        for quest in sampleQuests {
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:32:            let e = LifeEntity.fromQuest(quest)
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:79:        lifeContext.pushSnapshotToWidgets(from: sampleQuests)
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:97:        let strictLeash = DataLeashState.strictDefault   // everything blocked
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:98:        let fullyOpen = DataLeashState(
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:135:        let noteReflectionBlocked = NotesIntegration.reflectionPayload(
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:141:        let noteReflectionOK = NotesIntegration.reflectionPayload(
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:147:        let noteReflectionDenied = NotesIntegration.reflectionPayload(
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:169:        Notes:  reflection empty=\(noteReflectionBlocked == nil ? "PASS" : "FAIL")
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:170:                reflection ok=\(noteReflectionOK == nil ? "FAIL" : "PASS")
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:171:                reflection denied=\(noteReflectionDenied == nil ? "PASS" : "FAIL")
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:182:            && (noteReflectionBlocked == nil)
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:183:            && (noteReflectionOK != nil)
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:184:            && (noteReflectionDenied == nil)
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:201:            _ = try SacredEchoStore.seal(
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:210:        } catch EchoError.emptyReflection {
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:219:            _ = try SacredEchoStore.seal(
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:236:        let (ct, n, tag) = try! SacredEchoCipher.seal(
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:240:        let opened = try! SacredEchoCipher.open(
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:250:            _ = try SacredEchoCipher.open(ciphertext: tampered, nonce: n, tag: tag, echoID: id)
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:259:            _ = try SacredEchoCipher.open(
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:269:        let echoForLifecycle = SacredEcho(
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:277:        SacredEcho.nowOverride = { Date().addingTimeInterval(60 * 60 * 24 * 30) }
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:279:        SacredEcho.nowOverride = nil
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:301:        // Reflection-gate check: dormant when no reflections exist.
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:304:            coherenceScore: 0.5, completedQuestCount: 0
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:313:            && mentorDialogue.candidates.allSatisfy { $0.citedReflectionID != nil }
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:320:            all citations sourced:   \(mentorDialogue.candidates.allSatisfy { $0.citedReflectionID != nil } ? "PASS" : "FAIL")
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:355:                attributes: ["source": "WeaveQuest"]
Sources/OneWeave/OneWeavePrototype+GraphValidation.swift:402:        // (AppLifecycleConstants.envelopeKeyID); the SacredEchoCipher vault
Sources/OneWeave/DataLeashSettings.swift:2://  DataLeashSettings.swift
Sources/OneWeave/DataLeashSettings.swift:14:// MARK: - DataLeashState (shared, observable)
Sources/OneWeave/DataLeashSettings.swift:16:public struct DataLeashState: Codable, Equatable {
Sources/OneWeave/DataLeashSettings.swift:22:    public static let strictDefault = DataLeashState(
Sources/OneWeave/DataLeashSettings.swift:45:public final class DataLeashSettingsRecord {
Sources/OneWeave/DataLeashSettings.swift:51:    public init(state: DataLeashState = .strictDefault) {
Sources/OneWeave/DataLeashSettings.swift:58:    public func toState() -> DataLeashState {
Sources/OneWeave/DataLeashSettings.swift:62:        return DataLeashState(
Sources/OneWeave/DataLeashSettings.swift:68:    public func apply(_ state: DataLeashState) {
Sources/OneWeave/DataLeashSettings.swift:78:public struct DataLeashSettingsView: View {
Sources/OneWeave/DataLeashSettings.swift:80:    @State private var state: DataLeashState = .strictDefault
Sources/OneWeave/DataLeashSettings.swift:142:        let descriptor = FetchDescriptor<DataLeashSettingsRecord>(
Sources/OneWeave/DataLeashSettings.swift:148:            let record = DataLeashSettingsRecord()
Sources/OneWeave/DataLeashSettings.swift:156:        let descriptor = FetchDescriptor<DataLeashSettingsRecord>(
Sources/OneWeave/DataLeashSettings.swift:162:            let record = DataLeashSettingsRecord(state: state)
Sources/OneWeave/DataLeashSettings.swift:172:    /// Fetch the current DataLeashState. Caller is expected to refresh after settings changes.
Sources/OneWeave/DataLeashSettings.swift:176:    func currentLeash(in modelContext: ModelContext? = nil) -> DataLeashState {
Sources/OneWeave/DataLeashSettings.swift:181:        let descriptor = FetchDescriptor<DataLeashSettingsRecord>(
Sources/OneWeave/DataLeashSettings.swift:192:    func currentLeash() -> DataLeashState {
Sources/OneWeave/RelationshipDecayTracker.swift:35://    3. Reflection-gated. Suggesting a heavy outreach (e.g., "you haven't
Sources/OneWeave/RelationshipDecayTracker.swift:126:    public let requiresReflection: Bool       // true for severe prompts
Sources/OneWeave/RelationshipDecayTracker.swift:134:        requiresReflection: Bool
Sources/OneWeave/RelationshipDecayTracker.swift:141:        self.requiresReflection = requiresReflection
Sources/OneWeave/RelationshipDecayTracker.swift:211:                requiresReflection: severity == .severe
Sources/OneWeave/OneWeaveSnapshotStore.swift:9:    var topQuestTitle: String?
Sources/OneWeave/OneWeaveSnapshotStore.swift:10:    var topQuestDomain: String?
Sources/OneWeave/OneWeaveSnapshotStore.swift:11:    var activeQuestTitles: [String]
Sources/OneWeave/OneWeaveSnapshotStore.swift:25:        topQuestTitle: nil,
Sources/OneWeave/OneWeaveSnapshotStore.swift:26:        topQuestDomain: nil,
Sources/OneWeave/OneWeaveSnapshotStore.swift:27:        activeQuestTitles: [],
Sources/OneWeave/OneWeaveSnapshotStore.swift:47:        #if canImport(WidgetKit)
Sources/OneWeave/OneWeaveSnapshotStore.swift:48:        WidgetCenter.shared.reloadAllTimelines()
Sources/OneWeave/TimelineService.swift:110:// Global best practice: All events stay local unless user explicitly syncs (private CloudKit only).
Sources/OneWeave/OneWeaveWidgetStubs.swift:1:// OneWeaveWidgetStubs.swift
Sources/OneWeave/OneWeaveWidgetStubs.swift:2:// Phase 8 production: Harmony/Quest widgets production + App Intents + Live Activities
Sources/OneWeave/OneWeaveWidgetStubs.swift:4:// - Harmony Widget (small/medium via WidgetKit): TimelineProvider pulls harmonyScore, top active/suggested quest from LifeContext/@Query; mini 4-thread tapestry preview + "Open OneWeave". 
Sources/OneWeave/OneWeaveWidgetStubs.swift:9:// Post production; requires Xcode target setup for WidgetExtension (App Group for sharing snapshot JSON/UserDefaults).
Sources/OneWeave/OneWeaveWidgetStubs.swift:15:import WidgetKit
Sources/OneWeave/OneWeaveWidgetStubs.swift:21:// MARK: - Harmony Widget (small/medium)
Sources/OneWeave/OneWeaveWidgetStubs.swift:22:struct HarmonyWidgetProvider: TimelineProvider {
Sources/OneWeave/OneWeaveWidgetStubs.swift:48:struct HarmonyWidget: Widget {
Sources/OneWeave/OneWeaveWidgetStubs.swift:49:    let kind: String = "OneWeaveHarmonyWidget"
Sources/OneWeave/OneWeaveWidgetStubs.swift:51:    var body: some WidgetConfiguration {
Sources/OneWeave/OneWeaveWidgetStubs.swift:52:        StaticConfiguration(kind: kind, provider: HarmonyWidgetProvider()) { entry in
Sources/OneWeave/OneWeaveWidgetStubs.swift:53:            HarmonyWidgetView(entry: entry)
Sources/OneWeave/OneWeaveWidgetStubs.swift:61:struct HarmonyWidgetView: View {
Sources/OneWeave/OneWeaveWidgetStubs.swift:69:            if let q = entry.snapshot.topQuestTitle {
Sources/OneWeave/OneWeaveWidgetStubs.swift:70:                Text("Quest: \(q)")
Sources/OneWeave/OneWeaveWidgetStubs.swift:86:// MARK: - Quest Widget production (medium family, per Phase 8 concrete)
Sources/OneWeave/OneWeaveWidgetStubs.swift:87:struct QuestWidgetProvider: TimelineProvider {
Sources/OneWeave/OneWeaveWidgetStubs.swift:88:    typealias Entry = QuestEntry
Sources/OneWeave/OneWeaveWidgetStubs.swift:90:    func production(in context: Context) -> QuestEntry {
Sources/OneWeave/OneWeaveWidgetStubs.swift:91:        QuestEntry(date: Date(), quests: [
Sources/OneWeave/OneWeaveWidgetStubs.swift:92:            OneWeaveQuestStub(title: "3-day body awareness", domain: "Self", estMinutes: 15, essence: 8),
Sources/OneWeave/OneWeaveWidgetStubs.swift:93:            OneWeaveQuestStub(title: "Log 1 CareKin interaction", domain: "CareKin", estMinutes: 20, essence: 12)
Sources/OneWeave/OneWeaveWidgetStubs.swift:97:    func getSnapshot(in context: Context, completion: @escaping (QuestEntry) -> ()) {
Sources/OneWeave/OneWeaveWidgetStubs.swift:98:        let q = OneWeaveQuestStub(title: "Reflect on legacy story", domain: "Meaning", estMinutes: 10, essence: 15)
Sources/OneWeave/OneWeaveWidgetStubs.swift:99:        completion(QuestEntry(date: Date(), quests: [q]))
Sources/OneWeave/OneWeaveWidgetStubs.swift:102:    func getTimeline(in context: Context, completion: @escaping (Timeline<QuestEntry>) -> ()) {
Sources/OneWeave/OneWeaveWidgetStubs.swift:104:            OneWeaveQuestStub(title: "Audit 1 subscription leak", domain: "Stewardship", estMinutes: 5, essence: 6),
Sources/OneWeave/OneWeaveWidgetStubs.swift:105:            OneWeaveQuestStub(title: "Schedule non-digital meetup", domain: "CareKin", estMinutes: 30, essence: 10)
Sources/OneWeave/OneWeaveWidgetStubs.swift:107:        let entry = QuestEntry(date: Date(), quests: quests)
Sources/OneWeave/OneWeaveWidgetStubs.swift:113:struct OneWeaveQuestStub: Identifiable, Codable {
Sources/OneWeave/OneWeaveWidgetStubs.swift:121:struct QuestEntry: TimelineEntry {
Sources/OneWeave/OneWeaveWidgetStubs.swift:123:    let quests: [OneWeaveQuestStub]
Sources/OneWeave/OneWeaveWidgetStubs.swift:126:struct QuestWidget: Widget {
Sources/OneWeave/OneWeaveWidgetStubs.swift:127:    let kind: String = "OneWeaveQuestWidget"
Sources/OneWeave/OneWeaveWidgetStubs.swift:129:    var body: some WidgetConfiguration {
Sources/OneWeave/OneWeaveWidgetStubs.swift:130:        StaticConfiguration(kind: kind, provider: QuestWidgetProvider()) { entry in
Sources/OneWeave/OneWeaveWidgetStubs.swift:131:            QuestWidgetView(entry: entry)
Sources/OneWeave/OneWeaveWidgetStubs.swift:133:        .configurationDisplayName("OneWeave Quests")
Sources/OneWeave/OneWeaveWidgetStubs.swift:139:struct QuestWidgetView: View {
Sources/OneWeave/OneWeaveWidgetStubs.swift:140:    var entry: QuestEntry
Sources/OneWeave/OneWeaveWidgetStubs.swift:161:// MARK: - App Intents for Siri/Shortcuts
Sources/OneWeave/OneWeaveWidgetStubs.swift:162:struct LogWeaveIntent: AppIntent {
Sources/OneWeave/OneWeaveWidgetStubs.swift:175:struct CompleteQuestIntent: AppIntent {
Sources/OneWeave/OneWeaveWidgetStubs.swift:176:    static var title: LocalizedStringResource = "Complete Quest with Reflection"
Sources/OneWeave/OneWeaveWidgetStubs.swift:177:    @Parameter(title: "Reflection Note") var note: String
Sources/OneWeave/OneWeaveWidgetStubs.swift:185:struct ShowHarmonyIntent: AppIntent {
Sources/OneWeave/OneWeaveWidgetStubs.swift:191:struct OneWeaveLiveActivityAttributes: ActivityAttributes {
Sources/OneWeave/OneWeaveWidgetStubs.swift:201:// Usage: In main app: Activity<OneWeaveLiveActivityAttributes>.request(...) with initial content state from LifeContext
Sources/OneWeave/OneWeaveWidgetStubs.swift:202:// Widget for Live Activity UI in separate target.
Sources/OneWeave/OneWeaveWidgetStubs.swift:204:// Widget bundle for extension
Sources/OneWeave/OneWeaveWidgetStubs.swift:205:#if canImport(WidgetKit) && WIDGET_EXTENSION
Sources/OneWeave/OneWeaveWidgetStubs.swift:207:struct OneWeaveWidgets: WidgetBundle {
Sources/OneWeave/OneWeaveWidgetStubs.swift:208:    var body: some Widget {
Sources/OneWeave/OneWeaveWidgetStubs.swift:209:        HarmonyWidget()
Sources/OneWeave/OneWeaveWidgetStubs.swift:210:        QuestWidget()
Sources/OneWeave/OneWeaveWidgetStubs.swift:215:// - Add to Xcode: File > New > Target > Widget Extension; share app group with main OneWeave target for snapshot JSON.
Sources/OneWeave/OneWeaveWidgetStubs.swift:217:// - Harmony/quest focus per Phase 8 + DESIGN peripheral hooks. Production implementation includes full Harmony + Quest providers/views + intents + live attrs (polished per concrete).
Sources/OneWeave/OneWeaveWidgetStubs.swift:219:// - Production widget preview (Harmony + Quest) integrated in OneWeavePrototype.swift (sim UI using snapshot-like data from LifeContext for testing flows).
Sources/OneWeave/ResonanceOracle.swift:96:    static func commitWeave(from simulation: ResonanceSimulation, into context: LifeContext, userReflection: String, modelContext: ModelContext? = nil) {
Sources/OneWeave/ResonanceOracle.swift:97:        guard !userReflection.trimmingCharacters(in: .whitespaces).isEmpty else {
Sources/OneWeave/ResonanceOracle.swift:98:            print("[Oracle] Reflection gate: Must reflect before committing")
Sources/OneWeave/ResonanceOracle.swift:105:            summary: "Simulated resonance: \(String(format: "%.2f", simulation.coherenceDelta)) coherence. Reflection: \(userReflection)",
Sources/OneWeave/ResonanceOracle.swift:125:                "reflection": userReflection,
Sources/OneWeave/ResonanceOracle.swift:135:        let quests: [WeaveQuest] = (try? modelContext?.fetch(FetchDescriptor<WeaveQuest>())) ?? []
Sources/OneWeave/ResonanceOracle.swift:136:        context.pushSnapshotToWidgets(from: quests)
Sources/OneWeave/P2PWeaveShare.swift:17:    let senderReflectionNote: String?  // Required if reflection gate
Sources/OneWeave/P2PWeaveShare.swift:59:            receiveAndIntegrate(share: share, into: context, userReflection: trimmed, modelContext: modelContext)
Sources/OneWeave/P2PWeaveShare.swift:107:        print("  Reflection required: \(share.reflectionRequired)")
Sources/OneWeave/P2PWeaveShare.swift:111:        // DTLS mandatory. Handoff to relay if direct fails (15-20%).
Sources/OneWeave/P2PWeaveShare.swift:125:    // MARK: - Create Share with Reflection Gate + Data Leash
Sources/OneWeave/P2PWeaveShare.swift:129:        requireReflection: Bool = true,
Sources/OneWeave/P2PWeaveShare.swift:130:        senderReflection: String? = nil
Sources/OneWeave/P2PWeaveShare.swift:148:        if requireReflection && senderReflection == nil {
Sources/OneWeave/P2PWeaveShare.swift:149:            print("[P2P] Reflection gate: Must provide note before sharing sensitive entities")
Sources/OneWeave/P2PWeaveShare.swift:172:            reflectionRequired: requireReflection,
Sources/OneWeave/P2PWeaveShare.swift:174:            senderReflectionNote: senderReflection,
Sources/OneWeave/P2PWeaveShare.swift:182:    // MARK: - Receive + Integrate with Reflection Gate
Sources/OneWeave/P2PWeaveShare.swift:184:    static func receiveAndIntegrate(share: WeaveCircleShare, into context: LifeContext, userReflection: String? = nil, modelContext: ModelContext? = nil) {
Sources/OneWeave/P2PWeaveShare.swift:185:        // Reflection Gate: when the share requires reflection, we MUST NOT append anything
Sources/OneWeave/P2PWeaveShare.swift:189:            let trimmed = userReflection?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
Sources/OneWeave/P2PWeaveShare.swift:191:                print("[P2P] Reflection gate active. Held \(share.entities.count) entities pending reflection. No data written to graph.")
Sources/OneWeave/P2PWeaveShare.swift:222:        let note = share.senderReflectionNote ?? userReflection ?? ""
Sources/OneWeave/P2PWeaveShare.swift:260:            requireReflection: true,
Sources/OneWeave/P2PWeaveShare.swift:261:            senderReflection: reflection
Sources/OneWeave/LifeContext.swift:56:    var previousCognitiveLoadReadingJSON: String = ""
Sources/OneWeave/LifeContext.swift:61:// Quests persist in activeQuests array; updated on accept/complete.
Sources/OneWeave/LifeContext.swift:62:var activeQuests: [UUID] = []
Sources/OneWeave/LifeContext.swift:63:    var completedQuestCount: Int = 0
Sources/OneWeave/LifeContext.swift:67:    // Seasons: user or auto tag. On change: reflection gate, chapter summary, Essence burst.
Sources/OneWeave/LifeContext.swift:68:    var currentSeason: String = "Spring"
Sources/OneWeave/LifeContext.swift:71:    // FamilyPod.swift:330/335/338 references `context.threads`, `context.currentSeasonName`,
Sources/OneWeave/LifeContext.swift:76:    var currentSeasonName: String { currentSeason }
Sources/OneWeave/LifeContext.swift:89:    func pushSnapshotToWidgets(from quests: [WeaveQuest] = []) {
Sources/OneWeave/LifeContext.swift:91:        let activeTitles = activeQuests.prefix(2).compactMap { lookup[$0]?.title }
Sources/OneWeave/LifeContext.swift:92:        let topQuest = activeQuests.first.flatMap { lookup[$0] }
Sources/OneWeave/LifeContext.swift:99:            topQuestTitle: topQuest?.title,
Sources/OneWeave/LifeContext.swift:100:            topQuestDomain: topQuest?.domains.first,
Sources/OneWeave/LifeContext.swift:101:            activeQuestTitles: activeTitles,
Sources/OneWeave/LifeContext.swift:111:    var seasonReflectionCompleted: Bool = false
Sources/OneWeave/LifeContext.swift:113:    func changeSeason(to newSeason: String) {
Sources/OneWeave/LifeContext.swift:114:        if newSeason != currentSeason {
Sources/OneWeave/LifeContext.swift:115:            let old = currentSeason
Sources/OneWeave/LifeContext.swift:116:            currentSeason = newSeason
Sources/OneWeave/LifeContext.swift:118:            seasonReflectionCompleted = false  // gate re-arms; full +20 only on reflection commit
Sources/OneWeave/LifeContext.swift:119:            values["season"] = newSeason
Sources/OneWeave/LifeContext.swift:120:            // Reflection-gated burst (constitution: reflection-gated principle).
Sources/OneWeave/LifeContext.swift:122:            // and stage the full +20 burst behind seasonReflectionCompleted = true.
Sources/OneWeave/LifeContext.swift:124:            essenceLedger.append("+2 season transition tick \(old) → \(newSeason) (full +20 burst pending reflection)")
Sources/OneWeave/LifeContext.swift:125:        pushSnapshotToWidgets()
Sources/OneWeave/LifeContext.swift:130:    func completeSeasonReflection(note: String) {
Sources/OneWeave/LifeContext.swift:136:        if !seasonReflectionCompleted {
Sources/OneWeave/LifeContext.swift:137:            seasonReflectionCompleted = true
Sources/OneWeave/LifeContext.swift:141:            let summaryEvent = TimelineEvent(thread: "Meaning", type: "season_chapter_summary", payload: ["season": currentSeason, "reflection": trimmed], affectsEnergy: true)
Sources/OneWeave/LifeContext.swift:454:        pushSnapshotToWidgets()
Sources/OneWeave/LifeContext.swift:461:    /// `minReflectionChars` characters of substance (constitution: anti-bypass —
Sources/OneWeave/LifeContext.swift:466:    /// via `minExitReflectionChars`; completeQuest was inconsistent (accepted 1 char).
Sources/OneWeave/LifeContext.swift:467:    func completeQuest(_ questId: UUID, reflection: String, context: ModelContext) {
Sources/OneWeave/LifeContext.swift:469:        let minChars = 20  // mirrors FamilyPod.minExitReflectionChars
Sources/OneWeave/LifeContext.swift:483:        completedQuestCount += 1
Sources/OneWeave/LifeContext.swift:484:        activeQuests.removeAll { $0 == questId }
Sources/OneWeave/LifeContext.swift:490:            summary: "Quest completed",
Sources/OneWeave/LifeContext.swift:506:    case selfFocus = "SelfFocus"
Sources/OneWeave/LifeContext.swift:520:        pushSnapshotToWidgets()
Sources/OneWeave/LifeContext.swift:532:        pushSnapshotToWidgets()
Sources/OneWeave/LifeContext.swift:537:        case .selfFocus:
Sources/OneWeave/LifeContext.swift:540:            // Would bias next suggestions toward Stewardship-like in real QuestService
Sources/OneWeave/LifeContext.swift:560:        pushSnapshotToWidgets()
Sources/OneWeave/BodyThreadSheet.swift:62:                                statusMessage = "Reflection required to count toward coherence."
Sources/OneWeave/BodyThreadSheet.swift:68:                            statusMessage = "Body Thread refreshed. Reflection stored in Weave Pause."
Sources/OneWeave/ThreadsOverviewView.swift:52:                        Text("Season: \(ctx.values["season"] ?? "—")")

exec
/bin/bash -lc "sed -n '1,220p' PRIVACY.md" in /root/hermes-workspace/projects/oneweave
 succeeded in 0ms:
# Privacy

OneWeave is a privacy-first Life OS. This document describes the threat
model, the privacy gates, the explicit anti-patterns we refuse to ship,
and the cryptographic primitives that protect user data.

## Threat model

**What we protect against:**

1. **Accidental data exposure** — user taps the wrong button, app
   accidentally sends data to a peer they didn't intend, app exports
   more than the user expected.
2. **Compromised peer** — a peer in the user's Weave Circle has been
   compromised; we want to limit what they can learn.
3. **Device loss / theft** — someone gains physical access to the
   device. We protect against offline extraction of plaintext.
4. **Forensic recovery** — someone pulls the SQLite store after the app
   has been uninstalled. We protect against plaintext recovery from
   the deleted store.
5. **Supply-chain model compromise** — an LLM or Core ML model behaves
   differently than designed. We minimize reliance on remote / opaque
   models.

**What we do NOT protect against:**

1. **Compromise of the user's own device's OS** — if iOS itself is
   compromised, we cannot prevent plaintext extraction from a running
   process.
2. **User chooses to share** — once the user types a reflection and
   explicitly approves a share, the reflection leaves the device. We
   don't have a "recall" mechanism.
3. **Screen recording / screenshots** — out of scope for an iOS app.

## The five privacy gates

Every commit-shaped action in OneWeave passes through at least one
privacy gate. Most pass through multiple. Each gate is enforced at the
type level (empty `String` → throws / returns empty) so it's not
possible to bypass by accident.

### Gate 1: Reflection gate

Every function that commits user-facing state takes a non-empty
`reflectionText: String` argument. Empty input → throws
`ReflectionError.empty` or returns an empty result.

Functions gated:
- `WeaveQuest.complete(reflectionText:)` — must be non-empty
- `P2PWeaveShare.drainPending(into:with:modelContext:)` — must be non-empty
- `GraphInsightGenerator.applyInsight(...)` — must be non-empty
- `CommandPalette.commit(...:reflectionText:)` — must be non-empty
- `BodyThreadWeaver.weaveIntoGraph(...:reflectionText:)` — must be non-empty
- `SacredEchoStore.open(...)` — implicit (decree + plaintext required)
- `SacredEchoStore.handDeliver(...:deliveryReflection:)` — must be non-empty
- `SacredEchoStore.release(...:releaseReflection:)` — must be non-empty
- `FamilyPodPolicy.exit(...:exitReflection:)` — must be ≥20 chars
- `PortableExportBuilder.build(...:userIntentReflection:leash:)` — must be non-empty
  for any non-localOnly leash; ≥30 chars for fullBundle

### Gate 2: Data Leash gate

Every iOS system integration reads `DataLeashPolicy.currentLeash(in:
modelContext)` BEFORE calling the framework. If the user's toggle is
off, the function returns before any framework call.

Gated integrations:
- EventKit (EKEventStore) — gated on `.calendar`
- Contacts (CNContactStore) — gated on `.contacts`
- HealthKit (HKHealthStore) — gated on `.healthMetric`
- Reminders (EKReminder) — gated on `.reminders`
- Mail (MFMailComposeViewController) — gated on `.mail`
- Notes (UniformTypeIdentifiers) — gated on `.notes`
- Body Thread (HealthKit-derived) — gated on `.bodyThread`
- P2P receive — gated on `.p2pReceive`
- Insight awards — gated on `.insights`

This pattern (consult leash BEFORE permission prompt) means a user who
turns off Health integration never sees the HealthKit permission prompt
in the first place.

### Gate 3: Consent gate (isUserReflection)

`LifeEntity.isUserReflection: Bool` distinguishes user-authored content
from system content. This is the Nemotron cycle-27 #39 fix — without
it, the Invisible Mentor could quote a calendar event's title as if it
were the user's own reflection.

Enforced in:
- `InvisibleMentor.makeInput(from:openedEchoes:)` — only seeds with
  `isUserReflection == true` are added to `reflections`.
- `SacredEchoStore.seal(...:into:modelContext:)` — the life-graph
  reflection entity created from a sealed echo is flagged
  `isUserReflection = false` (the echo's plaintext is not the user's
  current words).
- `PortableExportBuilder` — only entities with `isUserReflection == true`
  AND `leash.permitsReflections == true` have their `summary` text
  included in the journal export.

### Gate 4: Sacred Echo unlock gate

Sacred Echo plaintext is decrypted only when `unlockAt <= now`.
Decrypted plaintext is never persisted in SwiftData attributes — only
the `ciphertext + nonce + tag` triple is stored. The plaintext exists
only in the calling function's stack for the duration of the open
ritual.

Enforced in:
- `SacredEchoStore.open(...)` — throws `.notYetUnlocked` if
  `unlockAt > now`.
- `EchoMarkdownRenderer.render(...)` — only includes plaintext when
  `leash.permitsEchoPlaintext == true`.
- `PortableExportBuilder` — counts `echoPlaintextCount` separately;
  this is the only field where plaintext leaves the device.

### Gate 5: Fail-closed crypto gate

SacredEchoCipher generates a 256-bit seed on first launch and persists
it to the Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
There is **no deterministic fallback in production** code. The
deterministic test seed is `#if !canImport(Security)` only — it's never
compiled into a device build.

`#if canImport(Security)` branches use:
- `SecRandomCopyBytes` for nonce generation (with `/dev/urandom` fallback
  if SecRandom fails — Grok + Claude cycle-24 fix).
- `Keychain` for seed persistence.
- `CryptoKit.AES.GCM` for the cipher.

Linux builds (and the Python harness) use:
- `/dev/urandom` for randomness.
- A test seed (clearly marked as test-only) for cipher parity.

## Cryptographic primitives

| Purpose              | Algorithm              | Notes                                   |
|----------------------|------------------------|-----------------------------------------|
| Echo payload         | AES-256-GCM            | Authenticated encryption                |
| Per-echo key         | HKDF-SHA256            | vaultSeed + echoID → 32-byte key        |
| Vault seed storage   | Keychain               | `kSecAttrAccessibleAfterFirstUnlock`    |
| Random nonce         | SecRandomCopyBytes     | 12 bytes per echo; /dev/urandom fallback|
| Envelope persistence | AES-GCM (reuses seed)  | AppLifecycleCoordinator                 |
| Hash (checksum)      | SHA-256                | Portable export manifest                |

## Explicit anti-patterns

The codebase intentionally does NOT contain:

1. **No telemetry.** No analytics SDK. No "X users completed this quest
   today." No A/B testing.
2. **No social features.** No likes. No comments. No followers. No feed.
   Family Pod is the only multi-user concept and it is explicitly
   anti-social (≤6 people, no real-time, no reactions).
3. **No cloud sync.** iCloud is not used for backup (the user can opt in
   to iCloud Drive for the portable export bundle, but the SwiftData
   store stays local).
4. **No remote LLM.** All synthesis (Invisible Mentor, Resonance
   Oracle, Cross-Domain Insights) is on-device against the user's local
   data.
5. **No Core ML models.** The Body-Thread Weaver computes a graded
   coherence value in pure Swift; no model is loaded.
6. **No "seen by" counters.** Family Pod digests do not report who
   opened them.
7. **No leaderboards.** No comparisons between users.
8. **No nudges to engage.** No "you haven't written today" badges.
9. **No remote configuration.** No "feature flags" loaded from a server.
10. **No ads. No third-party SDKs.**

## Data residency

All user data — LifeContext, LifeGraph, Sacred Echoes, threads,
timeline events, quests, insights — lives in the local SwiftData
store. The store path is:

```
~/Library/Application Support/OneWeave/OneWeave.store
```

The widget snapshot lives in the App Group container:

```
groupContainerURL(forSecurityApplicationGroupIdentifier:
                  "group.com.oneweave")/
   Library/Caches/oneweave.snapshot.v1
```

Family Pod messages are encoded on-device, then handed to the P2P
layer (Network framework or WebRTC) for delivery. The P2P layer is
end-to-end encrypted (Signal Protocol in production; CryptoKit
ChaChaPoly in the Linux harness).

## Incident response

If a privacy gate is discovered to have been bypassed:

1. **Block the build.** Add a regression test to the appropriate
   `.research/validate_*.py` file.
2. **Audit past data.** Run the audit on the production store (or
   notify users if breach is significant).
3. **Document in `SECURITY.md`.** Add a CVE-style entry with timeline.

If you find a bypass, please open a private issue (not public) until
the fix is shipped.
codex
1. **A. Top 10 Missing iOS 17+ Platform Features**

1. **Real App Intents + AppShortcutsProvider**  
   Complexity: M. Mac: 1-2 days. Privacy: actions must use local SwiftData/App Group only; durable writes require reflection text. Existing stubs in [OneWeaveWidgetStubs.swift](/root/hermes-workspace/projects/oneweave/Sources/OneWeave/OneWeaveWidgetStubs.swift:161) are not enough.

2. **Widget Extension target with App Group snapshots**  
   Complexity: M. Mac: 1-2 days. Privacy: only derived summaries in `group.com.oneweave`; never raw reflections or Echo plaintext.

3. **ActivityKit Live Activities**  
   Complexity: M/L. Mac: 2-3 days. Privacy: Lock Screen must avoid sensitive text by default; use redacted titles unless user opts in.

4. **Core Spotlight indexing**  
   Complexity: M. Mac: 1-2 days. Privacy: opt-in per category; index titles, dates, thread, non-sensitive summaries only. Reflections off by default.

5. **NSUserActivity + Handoff**  
   Complexity: S/M. Mac: 1 day. Privacy: activity payloads should contain stable IDs/deep links, not content.

6. **Share Extension: share into OneWeave**  
   Complexity: L. Mac: 3-5 days. Privacy: imported Safari/Mail/Photos content lands in Quick Capture Inbox pending classification and reflection before graph commit.

7. **Focus Filters / Focus-aware mode**  
   Complexity: M. Mac: 2 days. Privacy: no Focus data persisted beyond local mode preference. Focus should tune surfacing, not infer user state aggressively.

8. **Interactive widgets for quest acceptance / reflection launch**  
   Complexity: M. Mac: 1-2 days after intents. Privacy: widget can accept/open, but complete still requires in-app reflection or App Intent parameter.

9. **iCloud/CloudKit opt-in sync architecture**  
   Complexity: L. Mac: 1-2 weeks. Privacy: defer. Constitution currently says no cloud sync; this requires explicit product/constitution decision.

10. **Watch app v1.2+**  
   Complexity: L. Mac: 1-2 weeks. Privacy: Watch should be glance/capture only: quick reflection, cognitive load glance, Sacred Echo countdown, quest timer.

2. **B. Top 8 App Intents**

```swift
struct LogReflectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Reflection"
    @Parameter(title: "Reflection") var text: String
    @Parameter(title: "Thread") var thread: LifeThreadEntity?
    func perform() async throws -> some IntentResult { /* validate non-empty; enqueue local capture */ .result() }
}

struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Capture"
    @Parameter(title: "Text") var text: String
    func perform() async throws -> some IntentResult { /* classify task/event/journal/decision/note */ .result() }
}

struct CompleteQuestIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Quest"
    @Parameter(title: "Quest") var quest: QuestEntity
    @Parameter(title: "Reflection") var reflection: String
    func perform() async throws -> some IntentResult { /* min 20 chars; complete local quest */ .result() }
}

struct ShowHarmonyIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Harmony"
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Your harmony is \(score)%")
    }
}

struct OpenSacredEchoIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Sacred Echo"
    @Parameter(title: "Echo") var echo: EchoEntity
    @Parameter(title: "Decree") var decree: String
    func perform() async throws -> some IntentResult { /* fail closed; open only if unlocked */ .result() }
}

struct StartQuestFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Quest Focus"
    @Parameter(title: "Quest") var quest: QuestEntity
    @Parameter(title: "Minutes") var minutes: Int
    func perform() async throws -> some IntentResult { /* start Live Activity */ .result() }
}

struct RecordDecisionIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Decision"
    @Parameter(title: "Decision") var decision: String
    @Parameter(title: "Reflection") var reflection: String
    func perform() async throws -> some IntentResult { /* create DecisionLog entry */ .result() }
}

struct BeginWeavePauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Begin Weave Pause"
    @Parameter(title: "Reflection") var reflection: String?
    func perform() async throws -> some IntentResult { /* open pause flow; optional note */ .result() }
}
```

Add `AppShortcutsProvider` phrases: “Log a reflection in OneWeave”, “Capture this in OneWeave”, “Complete my OneWeave quest”, “Check my OneWeave harmony”, “Open my Sacred Echo”, “Start OneWeave focus”, “Record a OneWeave decision”, “Begin Weave Pause”.

3. **C. Top 5 Widgets Beyond Existing Stubs**

1. **Sacred Echo Countdown**  
   Complexity: M. Mac: 1-2 days. Lock Screen accessory circular/rectangular + Home small. Privacy: show countdown and symbolic title only; plaintext never.

2. **Cognitive Load Gauge**  
   Complexity: M. Mac: 1 day. Lock Screen rectangular + Home small. Privacy: default labels “Low/Moderate/High”; numeric score opt-in.

3. **Morning Briefing Widget**  
   Complexity: M. Mac: 2 days. Home medium/large. Privacy: generated from local snapshot; no raw calendar/contact names unless toggled.

4. **Relationship Care Widget**  
   Complexity: M. Mac: 2 days. Home medium. Privacy: contact names hidden by default; “1 relationship needs care” unless Contacts leash allows display.

5. **Decision Follow-up Widget**  
   Complexity: S/M. Mac: 1 day. Home small/medium. Privacy: title-only or redacted; opens decision review.

4. **D. Top 5 Live Activities**

1. **Sacred Echo Unlock Countdown**  
   Complexity: M. Mac: 2 days. Privacy: no plaintext, no sensitive recipient names by default.

2. **Quest Focus Session**  
   Complexity: M. Mac: 2 days. Shows minutes left, thread color, reflection reminder at end. Privacy: quest title redaction toggle.

3. **Weave Pause / Cognitive Load Recovery**  
   Complexity: M. Mac: 2 days. Shows pause timer and load trend. Privacy: no cause list on Lock Screen.

4. **Season Transition Reflection Window**  
   Complexity: M. Mac: 1-2 days. Shows chapter transition pending reflection. Privacy: season name safe; summary hidden.

5. **Family Pod Hand Delivery / Nearby Share**  
   Complexity: L. Mac: 3-5 days. Shows transfer state. Privacy: only peer alias, no payload preview; Data Leash and reflection gate before integration.

5. **E. Top 5 Accessibility Deep-Dive Improvements**

1. **VoiceOver labels for graph/loom/canvas**  
   Complexity: M. Mac: 2 days. Privacy: spoken content should respect redaction settings.

2. **Custom accessibility rotor for Reflection Gate fields**  
   Complexity: M. Mac: 1-2 days. Lets users jump between “required reflection”, “pending quest”, “privacy warning”.

3. **Voice Control grammar for core actions**  
   Complexity: M. Mac: 1-2 days. Add stable labels: “Complete Quest”, “Open Reflection Gate”, “Seal Echo”.

4. **Switch Control path audit**  
   Complexity: M. Mac: 2 days. Every commit flow must be reachable without gestures or drag.

5. **Dynamic Type + reduced motion pass**  
   Complexity: M. Mac: 2-3 days. Calm animations already fit the product; honor Reduce Motion and avoid Canvas-only meaning.

6. **F. Localization Matrix**

1. **v1 should ship English only if launch speed dominates; v1.0.1/v1.1 should add Arabic.**  
   Complexity: M/L. Mac: 4-7 days for strings, layout, QA. Privacy: none direct.

2. **Recommended matrix:**  
   English: full UI, App Intents, widgets, App Store, privacy policy.  
   Arabic: onboarding, privacy gates, reflection flows, Sacred Echo, quests, widgets, App Intents phrases.  
   Later: French/Spanish only after product-market signal.

3. **Arabic requires RTL QA, not just translation.**  
   Test widget truncation, Dynamic Type, VoiceOver Arabic pronunciation, mixed Arabic/English thread names, and Sacred Echo ritual text.

7. **G. Privacy-Preserving Opt-In CloudKit Sync**

Defer to **v1.1+**, not v1. Current constitution and [PRIVACY.md](/root/hermes-workspace/projects/oneweave/PRIVACY.md:1) explicitly position OneWeave as local-only with no cloud sync. For paid sync, make it an explicit “Private iCloud Sync” setting, default off, with a migration consent screen.

Design: use user’s private CloudKit database only; no OneWeave server account. Encrypt sensitive payloads client-side before CloudKit using keys derived from Keychain/iCloud Keychain, with per-record zones for `LifeContext`, quests, timeline metadata, and encrypted Sacred Echo records. Never sync decrypted Echo plaintext. Widgets still read only local App Group snapshots. Spotlight indexes local device content only. Add “Pause Sync”, “Delete Cloud Copy”, “Export Before Sync”, and a privacy audit log.

Complexity: L. Mac: 2-4 weeks including conflict resolution, migration, App Review privacy nutrition labels, and device testing.
tokens used
31,693
1. **A. Top 10 Missing iOS 17+ Platform Features**

1. **Real App Intents + AppShortcutsProvider**  
   Complexity: M. Mac: 1-2 days. Privacy: actions must use local SwiftData/App Group only; durable writes require reflection text. Existing stubs in [OneWeaveWidgetStubs.swift](/root/hermes-workspace/projects/oneweave/Sources/OneWeave/OneWeaveWidgetStubs.swift:161) are not enough.

2. **Widget Extension target with App Group snapshots**  
   Complexity: M. Mac: 1-2 days. Privacy: only derived summaries in `group.com.oneweave`; never raw reflections or Echo plaintext.

3. **ActivityKit Live Activities**  
   Complexity: M/L. Mac: 2-3 days. Privacy: Lock Screen must avoid sensitive text by default; use redacted titles unless user opts in.

4. **Core Spotlight indexing**  
   Complexity: M. Mac: 1-2 days. Privacy: opt-in per category; index titles, dates, thread, non-sensitive summaries only. Reflections off by default.

5. **NSUserActivity + Handoff**  
   Complexity: S/M. Mac: 1 day. Privacy: activity payloads should contain stable IDs/deep links, not content.

6. **Share Extension: share into OneWeave**  
   Complexity: L. Mac: 3-5 days. Privacy: imported Safari/Mail/Photos content lands in Quick Capture Inbox pending classification and reflection before graph commit.

7. **Focus Filters / Focus-aware mode**  
   Complexity: M. Mac: 2 days. Privacy: no Focus data persisted beyond local mode preference. Focus should tune surfacing, not infer user state aggressively.

8. **Interactive widgets for quest acceptance / reflection launch**  
   Complexity: M. Mac: 1-2 days after intents. Privacy: widget can accept/open, but complete still requires in-app reflection or App Intent parameter.

9. **iCloud/CloudKit opt-in sync architecture**  
   Complexity: L. Mac: 1-2 weeks. Privacy: defer. Constitution currently says no cloud sync; this requires explicit product/constitution decision.

10. **Watch app v1.2+**  
   Complexity: L. Mac: 1-2 weeks. Privacy: Watch should be glance/capture only: quick reflection, cognitive load glance, Sacred Echo countdown, quest timer.

2. **B. Top 8 App Intents**

```swift
struct LogReflectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Reflection"
    @Parameter(title: "Reflection") var text: String
    @Parameter(title: "Thread") var thread: LifeThreadEntity?
    func perform() async throws -> some IntentResult { /* validate non-empty; enqueue local capture */ .result() }
}

struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Capture"
    @Parameter(title: "Text") var text: String
    func perform() async throws -> some IntentResult { /* classify task/event/journal/decision/note */ .result() }
}

struct CompleteQuestIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Quest"
    @Parameter(title: "Quest") var quest: QuestEntity
    @Parameter(title: "Reflection") var reflection: String
    func perform() async throws -> some IntentResult { /* min 20 chars; complete local quest */ .result() }
}

struct ShowHarmonyIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Harmony"
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Your harmony is \(score)%")
    }
}

struct OpenSacredEchoIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Sacred Echo"
    @Parameter(title: "Echo") var echo: EchoEntity
    @Parameter(title: "Decree") var decree: String
    func perform() async throws -> some IntentResult { /* fail closed; open only if unlocked */ .result() }
}

struct StartQuestFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Quest Focus"
    @Parameter(title: "Quest") var quest: QuestEntity
    @Parameter(title: "Minutes") var minutes: Int
    func perform() async throws -> some IntentResult { /* start Live Activity */ .result() }
}

struct RecordDecisionIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Decision"
    @Parameter(title: "Decision") var decision: String
    @Parameter(title: "Reflection") var reflection: String
    func perform() async throws -> some IntentResult { /* create DecisionLog entry */ .result() }
}

struct BeginWeavePauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Begin Weave Pause"
    @Parameter(title: "Reflection") var reflection: String?
    func perform() async throws -> some IntentResult { /* open pause flow; optional note */ .result() }
}
```

Add `AppShortcutsProvider` phrases: “Log a reflection in OneWeave”, “Capture this in OneWeave”, “Complete my OneWeave quest”, “Check my OneWeave harmony”, “Open my Sacred Echo”, “Start OneWeave focus”, “Record a OneWeave decision”, “Begin Weave Pause”.

3. **C. Top 5 Widgets Beyond Existing Stubs**

1. **Sacred Echo Countdown**  
   Complexity: M. Mac: 1-2 days. Lock Screen accessory circular/rectangular + Home small. Privacy: show countdown and symbolic title only; plaintext never.

2. **Cognitive Load Gauge**  
   Complexity: M. Mac: 1 day. Lock Screen rectangular + Home small. Privacy: default labels “Low/Moderate/High”; numeric score opt-in.

3. **Morning Briefing Widget**  
   Complexity: M. Mac: 2 days. Home medium/large. Privacy: generated from local snapshot; no raw calendar/contact names unless toggled.

4. **Relationship Care Widget**  
   Complexity: M. Mac: 2 days. Home medium. Privacy: contact names hidden by default; “1 relationship needs care” unless Contacts leash allows display.

5. **Decision Follow-up Widget**  
   Complexity: S/M. Mac: 1 day. Home small/medium. Privacy: title-only or redacted; opens decision review.

4. **D. Top 5 Live Activities**

1. **Sacred Echo Unlock Countdown**  
   Complexity: M. Mac: 2 days. Privacy: no plaintext, no sensitive recipient names by default.

2. **Quest Focus Session**  
   Complexity: M. Mac: 2 days. Shows minutes left, thread color, reflection reminder at end. Privacy: quest title redaction toggle.

3. **Weave Pause / Cognitive Load Recovery**  
   Complexity: M. Mac: 2 days. Shows pause timer and load trend. Privacy: no cause list on Lock Screen.

4. **Season Transition Reflection Window**  
   Complexity: M. Mac: 1-2 days. Shows chapter transition pending reflection. Privacy: season name safe; summary hidden.

5. **Family Pod Hand Delivery / Nearby Share**  
   Complexity: L. Mac: 3-5 days. Shows transfer state. Privacy: only peer alias, no payload preview; Data Leash and reflection gate before integration.

5. **E. Top 5 Accessibility Deep-Dive Improvements**

1. **VoiceOver labels for graph/loom/canvas**  
   Complexity: M. Mac: 2 days. Privacy: spoken content should respect redaction settings.

2. **Custom accessibility rotor for Reflection Gate fields**  
   Complexity: M. Mac: 1-2 days. Lets users jump between “required reflection”, “pending quest”, “privacy warning”.

3. **Voice Control grammar for core actions**  
   Complexity: M. Mac: 1-2 days. Add stable labels: “Complete Quest”, “Open Reflection Gate”, “Seal Echo”.

4. **Switch Control path audit**  
   Complexity: M. Mac: 2 days. Every commit flow must be reachable without gestures or drag.

5. **Dynamic Type + reduced motion pass**  
   Complexity: M. Mac: 2-3 days. Calm animations already fit the product; honor Reduce Motion and avoid Canvas-only meaning.

6. **F. Localization Matrix**

1. **v1 should ship English only if launch speed dominates; v1.0.1/v1.1 should add Arabic.**  
   Complexity: M/L. Mac: 4-7 days for strings, layout, QA. Privacy: none direct.

2. **Recommended matrix:**  
   English: full UI, App Intents, widgets, App Store, privacy policy.  
   Arabic: onboarding, privacy gates, reflection flows, Sacred Echo, quests, widgets, App Intents phrases.  
   Later: French/Spanish only after product-market signal.

3. **Arabic requires RTL QA, not just translation.**  
   Test widget truncation, Dynamic Type, VoiceOver Arabic pronunciation, mixed Arabic/English thread names, and Sacred Echo ritual text.

7. **G. Privacy-Preserving Opt-In CloudKit Sync**

Defer to **v1.1+**, not v1. Current constitution and [PRIVACY.md](/root/hermes-workspace/projects/oneweave/PRIVACY.md:1) explicitly position OneWeave as local-only with no cloud sync. For paid sync, make it an explicit “Private iCloud Sync” setting, default off, with a migration consent screen.

Design: use user’s private CloudKit database only; no OneWeave server account. Encrypt sensitive payloads client-side before CloudKit using keys derived from Keychain/iCloud Keychain, with per-record zones for `LifeContext`, quests, timeline metadata, and encrypted Sacred Echo records. Never sync decrypted Echo plaintext. Widgets still read only local App Group snapshots. Spotlight indexes local device content only. Add “Pause Sync”, “Delete Cloud Copy”, “Export Before Sync”, and a privacy audit log.

Complexity: L. Mac: 2-4 weeks including conflict resolution, migration, App Review privacy nutrition labels, and device testing.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           codex
1. **A. Top 10 Missing iOS 17+ Platform Features**

1. **Real Widget Extension target** beyond `OneWeaveWidgetStubs.swift`  
Complexity: M. Mac: 1-2 days. Privacy: snapshot-only via `group.com.oneweave`; never query full SwiftData from widget.

2. **AppShortcutsProvider + donated App Intents**  
Complexity: M. Mac: 1 day. Privacy: shortcuts must require explicit user input for reflection-gated writes.

3. **Core Spotlight indexing** for reflections, quests, decisions, insights, Sacred Echo metadata  
Complexity: M. Mac: 1-2 days. Privacy: opt-in, index titles/summaries only; exclude private plaintext and locked echo contents.

4. **NSUserActivity / Handoff / deep links**  
Complexity: S-M. Mac: 0.5-1 day. Privacy: activity payloads should contain opaque IDs only.

5. **Share Extension: share into OneWeave** from Safari, Mail, Photos, Notes  
Complexity: L. Mac: 3-5 days. Privacy: imported content lands in Quick Capture Inbox pending reflection and leash classification.

6. **Focus Filters**  
Complexity: M. Mac: 1-2 days. Privacy: OneWeave can expose “Reflection”, “Care”, “Stewardship”, “Low Cognitive Load” filters without leaking content.

7. **Live Activities / Dynamic Island** for time-bound reflection or quest sessions  
Complexity: M-L. Mac: 2-3 days. Privacy: display neutral labels by default; sensitive titles hidden on Lock Screen.

8. **Local notifications with interruption levels**  
Complexity: M. Mac: 1-2 days. Privacy: no body text unless user enables “show sensitive summaries”.

9. **iCloud / CloudKit opt-in sync**  
Complexity: L. Mac: 1-2 weeks. Privacy: off by default; paid tier candidate; client-side encrypted records preferred.

10. **Watch companion app**  
Complexity: L. Mac: 1-2 weeks. Privacy: glanceable state only; capture/reflection handoff to phone for sensitive writes.

2. **B. Top 8 App Intents To Implement**

```swift
struct LogReflectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Reflection"
    @Parameter(title: "Reflection") var reflection: String
    @Parameter(title: "Thread") var thread: OneWeaveThreadEntity?
    func perform() async throws -> some IntentResult { /* validate non-empty, enqueue capture */ .result() }
}

struct CompleteQuestIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Quest"
    @Parameter(title: "Quest") var quest: QuestEntity
    @Parameter(title: "Reflection") var reflection: String
    func perform() async throws -> some IntentResult { /* reflection gate, award essence */ .result() }
}

struct ShowHarmonyIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Harmony"
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Your harmony is available in OneWeave.")
    }
}

struct OpenSacredEchoIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Sacred Echo"
    @Parameter(title: "Echo") var echo: SacredEchoEntity
    @Parameter(title: "Reflection") var reflection: String
    func perform() async throws -> some IntentResult { /* unlock if due, fail closed */ .result() }
}

struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Capture"
    @Parameter(title: "Text") var text: String
    func perform() async throws -> some IntentResult { /* classify task/event/journal/etc */ .result() }
}

struct StartWeavePauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Weave Pause"
    @Parameter(title: "Minutes") var minutes: Int
    func perform() async throws -> some IntentResult { /* start timer/live activity */ .result() }
}

struct RecordDecisionIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Decision"
    @Parameter(title: "Decision") var title: String
    @Parameter(title: "Reasoning") var reasoning: String
    func perform() async throws -> some IntentResult { /* save private decision */ .result() }
}

struct ShareToFamilyPodIntent: AppIntent {
    static var title: LocalizedStringResource = "Share to Family Pod"
    @Parameter(title: "Summary") var summary: String
    @Parameter(title: "Reflection") var reflection: String
    func perform() async throws -> some IntentResult { /* leash + reflection gate */ .result() }
}
```

All eight are M complexity except `ShowHarmonyIntent` S and `ShareToFamilyPodIntent` L. Mac effort: 3-5 days total with entities, phrase discovery, tests, and deep links. Privacy: every write intent needs reflection validation and explicit user confirmation.

Suggested App Shortcut phrases: “Log a reflection in OneWeave”, “Complete my OneWeave quest”, “Check my harmony”, “Open my Sacred Echo”, “Start a Weave Pause”.

3. **C. Top 5 Widgets Beyond Existing Harmony + Quest Stubs**

1. **Lock Screen Cognitive Load Gauge**  
Complexity: M. Mac: 1 day. Privacy: show low/medium/high only, no causes.

2. **Sacred Echo Countdown Widget**  
Complexity: M. Mac: 1 day. Privacy: default title “Echo unlocks soon”; user can opt into echo title.

3. **Reflection Gate Widget**  
Complexity: S-M. Mac: 0.5-1 day. Privacy: launches reflection composer; stores nothing in widget.

4. **Relationship Care Widget**  
Complexity: M. Mac: 1-2 days. Privacy: initials or relationship role only unless user opts into names.

5. **Decision Follow-up Widget**  
Complexity: M. Mac: 1 day. Privacy: private decision titles hidden on Lock Screen.

4. **D. Top 5 Live Activities**

1. **Sacred Echo Countdown**  
Complexity: M. Mac: 2 days. Privacy: lock-screen redaction required.

2. **Weave Pause Session**  
Complexity: M. Mac: 1-2 days. Privacy: neutral timer, no health causes.

3. **Active IRL Quest**  
Complexity: M. Mac: 2 days. Privacy: show generic quest category unless user allows title.

4. **Cognitive Load Recovery Trend**  
Complexity: L. Mac: 3 days. Privacy: avoid HealthKit-derived specifics on Lock Screen.

5. **Season Transition Reflection Window**  
Complexity: M. Mac: 1-2 days. Privacy: show season name and time left; reflection content stays in app.

5. **E. Top 5 Accessibility Deep-Dive Improvements**

1. **VoiceOver audit for Loom Canvas**  
Complexity: L. Mac: 2-3 days. Privacy: announce node labels only if visible in current privacy mode.

2. **Custom rotor for Reflection Gate fields**  
Complexity: M. Mac: 1 day. Privacy: rotor navigates empty/required reflection fields, not content previews.

3. **Voice Control grammar**  
Complexity: M. Mac: 1-2 days. Privacy: commands like “Complete quest”, “Open reflection”, “Hide private details”.

4. **Switch Control predictable order**  
Complexity: M. Mac: 1 day. Privacy: no hidden sensitive elements in focus order.

5. **Dynamic Type + reduced motion pass**  
Complexity: M. Mac: 1-2 days. Privacy: none, but important for calm-design constitution.

6. **F. Localization Matrix**

V1 should ship **English + Arabic** if bilingual users are a core target. Arabic adds real cost because it requires RTL layout verification, not just strings.

Matrix: app strings, onboarding, privacy copy, App Intents phrases, widget text, notifications, accessibility labels, App Store metadata.  
Complexity: L. Mac: 4-7 days initial, then ongoing. Privacy: localized privacy terms must match actual behavior exactly.

Recommendation: localize UI shells and App Store metadata for v1; keep long-form help/privacy professionally reviewed before App Store submission.

7. **G. Privacy-Preserving Opt-In CloudKit Sync Design**

Defer to **v1.1**, not v1.0. V1 already has enough Mac blockers: Xcode project, App Group, Widget target, AppShortcutsProvider, provisioning, migrations.

Design: off by default; explicit “Sync with iCloud” paywall/setting; client-side encrypt graph records before CloudKit; per-category sync toggles matching Data Leash; never sync locked Sacred Echo plaintext; sync only encrypted blobs plus minimal metadata; recovery/export remains local-first.

Complexity: L. Mac: 1-2 weeks. Privacy: strongest option is user-owned iCloud transport with OneWeave unable to read content. Tradeoff: conflict resolution, migration, and key recovery become product features, not plumbing.
tokens used
28,168
1. **A. Top 10 Missing iOS 17+ Platform Features**

1. **Real Widget Extension target** beyond `OneWeaveWidgetStubs.swift`  
Complexity: M. Mac: 1-2 days. Privacy: snapshot-only via `group.com.oneweave`; never query full SwiftData from widget.

2. **AppShortcutsProvider + donated App Intents**  
Complexity: M. Mac: 1 day. Privacy: shortcuts must require explicit user input for reflection-gated writes.

3. **Core Spotlight indexing** for reflections, quests, decisions, insights, Sacred Echo metadata  
Complexity: M. Mac: 1-2 days. Privacy: opt-in, index titles/summaries only; exclude private plaintext and locked echo contents.

4. **NSUserActivity / Handoff / deep links**  
Complexity: S-M. Mac: 0.5-1 day. Privacy: activity payloads should contain opaque IDs only.

5. **Share Extension: share into OneWeave** from Safari, Mail, Photos, Notes  
Complexity: L. Mac: 3-5 days. Privacy: imported content lands in Quick Capture Inbox pending reflection and leash classification.

6. **Focus Filters**  
Complexity: M. Mac: 1-2 days. Privacy: OneWeave can expose “Reflection”, “Care”, “Stewardship”, “Low Cognitive Load” filters without leaking content.

7. **Live Activities / Dynamic Island** for time-bound reflection or quest sessions  
Complexity: M-L. Mac: 2-3 days. Privacy: display neutral labels by default; sensitive titles hidden on Lock Screen.

8. **Local notifications with interruption levels**  
Complexity: M. Mac: 1-2 days. Privacy: no body text unless user enables “show sensitive summaries”.

9. **iCloud / CloudKit opt-in sync**  
Complexity: L. Mac: 1-2 weeks. Privacy: off by default; paid tier candidate; client-side encrypted records preferred.

10. **Watch companion app**  
Complexity: L. Mac: 1-2 weeks. Privacy: glanceable state only; capture/reflection handoff to phone for sensitive writes.

2. **B. Top 8 App Intents To Implement**

```swift
struct LogReflectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Reflection"
    @Parameter(title: "Reflection") var reflection: String
    @Parameter(title: "Thread") var thread: OneWeaveThreadEntity?
    func perform() async throws -> some IntentResult { /* validate non-empty, enqueue capture */ .result() }
}

struct CompleteQuestIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Quest"
    @Parameter(title: "Quest") var quest: QuestEntity
    @Parameter(title: "Reflection") var reflection: String
    func perform() async throws -> some IntentResult { /* reflection gate, award essence */ .result() }
}

struct ShowHarmonyIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Harmony"
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Your harmony is available in OneWeave.")
    }
}

struct OpenSacredEchoIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Sacred Echo"
    @Parameter(title: "Echo") var echo: SacredEchoEntity
    @Parameter(title: "Reflection") var reflection: String
    func perform() async throws -> some IntentResult { /* unlock if due, fail closed */ .result() }
}

struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Capture"
    @Parameter(title: "Text") var text: String
    func perform() async throws -> some IntentResult { /* classify task/event/journal/etc */ .result() }
}

struct StartWeavePauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Weave Pause"
    @Parameter(title: "Minutes") var minutes: Int
    func perform() async throws -> some IntentResult { /* start timer/live activity */ .result() }
}

struct RecordDecisionIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Decision"
    @Parameter(title: "Decision") var title: String
    @Parameter(title: "Reasoning") var reasoning: String
    func perform() async throws -> some IntentResult { /* save private decision */ .result() }
}

struct ShareToFamilyPodIntent: AppIntent {
    static var title: LocalizedStringResource = "Share to Family Pod"
    @Parameter(title: "Summary") var summary: String
    @Parameter(title: "Reflection") var reflection: String
    func perform() async throws -> some IntentResult { /* leash + reflection gate */ .result() }
}
```

All eight are M complexity except `ShowHarmonyIntent` S and `ShareToFamilyPodIntent` L. Mac effort: 3-5 days total with entities, phrase discovery, tests, and deep links. Privacy: every write intent needs reflection validation and explicit user confirmation.

Suggested App Shortcut phrases: “Log a reflection in OneWeave”, “Complete my OneWeave quest”, “Check my harmony”, “Open my Sacred Echo”, “Start a Weave Pause”.

3. **C. Top 5 Widgets Beyond Existing Harmony + Quest Stubs**

1. **Lock Screen Cognitive Load Gauge**  
Complexity: M. Mac: 1 day. Privacy: show low/medium/high only, no causes.

2. **Sacred Echo Countdown Widget**  
Complexity: M. Mac: 1 day. Privacy: default title “Echo unlocks soon”; user can opt into echo title.

3. **Reflection Gate Widget**  
Complexity: S-M. Mac: 0.5-1 day. Privacy: launches reflection composer; stores nothing in widget.

4. **Relationship Care Widget**  
Complexity: M. Mac: 1-2 days. Privacy: initials or relationship role only unless user opts into names.

5. **Decision Follow-up Widget**  
Complexity: M. Mac: 1 day. Privacy: private decision titles hidden on Lock Screen.

4. **D. Top 5 Live Activities**

1. **Sacred Echo Countdown**  
Complexity: M. Mac: 2 days. Privacy: lock-screen redaction required.

2. **Weave Pause Session**  
Complexity: M. Mac: 1-2 days. Privacy: neutral timer, no health causes.

3. **Active IRL Quest**  
Complexity: M. Mac: 2 days. Privacy: show generic quest category unless user allows title.

4. **Cognitive Load Recovery Trend**  
Complexity: L. Mac: 3 days. Privacy: avoid HealthKit-derived specifics on Lock Screen.

5. **Season Transition Reflection Window**  
Complexity: M. Mac: 1-2 days. Privacy: show season name and time left; reflection content stays in app.

5. **E. Top 5 Accessibility Deep-Dive Improvements**

1. **VoiceOver audit for Loom Canvas**  
Complexity: L. Mac: 2-3 days. Privacy: announce node labels only if visible in current privacy mode.

2. **Custom rotor for Reflection Gate fields**  
Complexity: M. Mac: 1 day. Privacy: rotor navigates empty/required reflection fields, not content previews.

3. **Voice Control grammar**  
Complexity: M. Mac: 1-2 days. Privacy: commands like “Complete quest”, “Open reflection”, “Hide private details”.

4. **Switch Control predictable order**  
Complexity: M. Mac: 1 day. Privacy: no hidden sensitive elements in focus order.

5. **Dynamic Type + reduced motion pass**  
Complexity: M. Mac: 1-2 days. Privacy: none, but important for calm-design constitution.

6. **F. Localization Matrix**

V1 should ship **English + Arabic** if bilingual users are a core target. Arabic adds real cost because it requires RTL layout verification, not just strings.

Matrix: app strings, onboarding, privacy copy, App Intents phrases, widget text, notifications, accessibility labels, App Store metadata.  
Complexity: L. Mac: 4-7 days initial, then ongoing. Privacy: localized privacy terms must match actual behavior exactly.

Recommendation: localize UI shells and App Store metadata for v1; keep long-form help/privacy professionally reviewed before App Store submission.

7. **G. Privacy-Preserving Opt-In CloudKit Sync Design**

Defer to **v1.1**, not v1.0. V1 already has enough Mac blockers: Xcode project, App Group, Widget target, AppShortcutsProvider, provisioning, migrations.

Design: off by default; explicit “Sync with iCloud” paywall/setting; client-side encrypt graph records before CloudKit; per-category sync toggles matching Data Leash; never sync locked Sacred Echo plaintext; sync only encrypted blobs plus minimal metadata; recovery/export remains local-first.

Complexity: L. Mac: 1-2 weeks. Privacy: strongest option is user-owned iCloud transport with OneWeave unable to read content. Tradeoff: conflict resolution, migration, and key recovery become product features, not plumbing.
