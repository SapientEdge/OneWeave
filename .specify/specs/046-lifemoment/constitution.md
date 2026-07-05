# OneWeave Constitution

**Version:** 2.1 — Updated 2026-06-29 (cycle 46: LifeMoment native feature; additive amendment — Principle 11 + Invariant 11)
**Previous version:** 2.0 (2026-06-27, post-Spec Kit + Graphify + Aider adoption)

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

### 8. Quiet Capture (added 2026-06-29, cycle 46)
- **LifeMoment** — capturing a moment of life (photo + Vision OCR + optional reflection) is frictionless (snap → reflection in 30s) but **never awards essence, streak, or mastery automatically**.
- Captured moments stay free-floating by default — no algorithmic categorization into a Thread. The user attaches manually, or never does.
- Promotion to gamified artifacts (Quest, Reflection, Sacred Echo, Insight) requires **explicit user action + non-empty reflection**. Existing reflection gates (Principle 4) apply unchanged.
- Storage is plaintext metadata by default for fast search. User can "Seal" a moment to encrypt OCR + image embedding text via `MomentSealer` (AES-256-GCM, fail-closed, `#if DEBUG` Linux test seed gated, mirror of `SacredEchoCipher`'s cryptographic discipline).
- **Per Claude review SPEC-12:** Empty `""` reflection does NOT count — `isUserReflection = !(reflection?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)`. Whitespace-only reflection is also rejected.

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
7a. **(amended 2026-06-29, cycle 46)** Data Leash now has **10 toggles** — the new 10th is `photos` (covers Photos library access + Vision OCR on user images). The toggle is registered as `IntegrationCategory.photos` in `iOSServiceIntegrations.swift` (added in cycle 46 V4 migration) and defaults to OFF for fresh installs. `LifeMoment.capture()` reads this toggle BEFORE any Photos/Vision call; off → capture returns a typed `PhotosDisabledError` and no moment is created.
8. **P2P encryption**: Signal Protocol via libsignal-client; STUN stun.l.google.com:19302; TURN self-hosted Coturn
9. **iOS minimum**: iOS 17+ (SwiftData requirement)
10. **Color convention** (for consistency across all views): Self=.blue, Stewardship=.green, CareKin=.orange, Meaning=.purple
11. **Moment Egress Boundary** (added 2026-06-29, cycle 46) — Vision-derived OCR + image embeddings + detected entities stored in `LifeMoment` MUST NEVER cross into TimelineEvent, LifeGraph edges, QuickCapture classification, FamilyPod sharing, P2P transmission, AppIntents return values, Widget snapshots, or PortableExport payloads. Only `userReflection` (user-authored text) and `userAssignedThread` (user-chosen) cross to other entities. When `LifeMoment.isSealed == true`, OCR + embeddings remain encrypted at rest; only unsealed on user-initiated view within the LifeMoment surface. `MomentSealer` uses HKDF info string `"OneWeaveMoment.v1"` for cryptographic isolation from SacredEchoVault keys (`"SacredEcho.<id>"`).

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

- v2.1 (2026-06-29): Added **Principle 8 (Quiet Capture)** and **Invariant 11 (Moment Egress Boundary)** to support native LifeMoment feature. Strictly additive — no existing principles or invariants modified. Documented in `.research/CYCLE46_LIFEMOMENT_SPEC.md`.
- v2.0 (2026-06-27): Added toolchain mandates, architectural invariants, reflection-gated principle, anti-addictive gamification details. Reflects post-Tier A/Round 2/Linux push reality.
- v1.0 (2026-06-24): Initial constitution.

---

*This constitution governs all OneWeave work and inherits global Hermes best practices.*