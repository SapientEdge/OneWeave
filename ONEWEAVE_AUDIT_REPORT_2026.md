# OneWeave Codebase Audit Report
**Date**: 2026-06-26  
**Auditor**: Hermes Subagent (local analysis only)  
**Scope**: /root/hermes-workspace/projects/oneweave/Sources/OneWeave/*.swift and related docs; /root/hermes-workspace/projects/oneweave-web/index.html and /root/hermes-workspace/deliverables/oneweave-pwa.html (PWA); supporting MD files; no external net calls beyond analysis.  
**Tools Used**: terminal (find, ls, semgrep), search_files (pattern/grep), read_file (multi-offset), todo tracking. No assumptions on other paths.

## Executive Summary
OneWeave implements a solid conceptual event-driven "ripple" architecture across 4 Life Threads (Self, Stewardship, CareKin, Meaning) using SwiftUI + SwiftData (iOS prototype) and a standalone gamified PWA (HTML/JS). Philosophy (calm tech, PbD, local-first) is well-documented in white papers. Core flows (emit → context update → UI ripple → state machine) are wired in places.

**However, significant gaps prevent production readiness:**
- **Security/Privacy**: No app-level encryption (contrary to white paper requirements for "encrypted at rest with user-controlled keys"). Plaintext storage + exports. Minimal consent. External dependencies in web version create leaks/tracking vectors. Raw sensitive personal data (goals, family tasks, stories, subs, "leaks") stored without redaction or minimization.
- **Code Quality**: Multiple compilation/runtime bugs (inheritance mismatch, method signature mismatches between seeder/calls/defs, missing properties, inconsistent APIs). Exports are stubs (text summaries, not real JSON). Docs claim "production-ready, no stubs, full export" but reality lags.
- **Completeness**: Missing real export/import, passphrase encryption, granular consent, tests, full data model serialization, PWA hardening, build artifacts. State machine and insights are on-device rule-based (good), but integration incomplete.

**Risk Level**: High for wellbeing app handling longitudinal personal/relational data. Device theft, export exposure, or devtools inspection leaks everything. White paper PbD (7 principles) not fully implemented.

**Recommendation**: Fix bugs immediately; implement encryption + consent before any TestFlight/build; treat as prototype, not shippable. Full production needs ~2-4 weeks focused hardening + tests.

**Files Audited** (~39 relevant): 20+ Swift sources, 2 large PWAs (~80k lines combined HTML/JS), 10+ MD docs/specs.

## 1. Security & Privacy Gaps (Critical for Production)
### Storage & Encryption
- **Swift (iOS)**:
  - Uses SwiftData (@Model for LifeContext, TimelineEvent, BasicSelfThread, StewardshipThread, CareKinThread, MeaningThread). Local SQLite under app container.
  - **No explicit encryption**: Relies on iOS device passcode + Secure Enclave (FileProtection default). White paper (ONEWEAVE_WHITE_PAPER.md, oneweave-whitepaper.md) requires "Raw event data stays on-device or **encrypted at rest with user-controlled keys**", "End-to-End Security", "user-controlled keys".
  - Payloads: `[String: String]` raw user text (e.g. "half-marathon training", "family admin during training", "modeling resilience for kids", subscription names/costs, stories). No redaction, no minimization.
  - `TimelineEvent.privacyLevel = "local-only"` (just a string, unenforced).
  - **Export**: SettingsView.swift `exportAllData()` produces **stub text summary** only (not full JSON of events/threads). ThreadDetailView similar. Claims of "real JSON export" in docs false. No encryption on export.
  - No Keychain, no CryptoKit usage in core. Seeding populates sensitive demo data.
- **PWA (web)**:
  - `localStorage.setItem('oneweave_state_v2', JSON.stringify(state))` — **plaintext, devtools-visible, device-accessible, no expiration**.
  - `exportData()`: plain JSON download.
  - `exportEncrypted()`: Uses Web Crypto AES-GCM + random key + IV. **Includes full JWK key + IV + encrypted in the same JSON file** (defeats purpose; user "keeps key safe" but it's bundled). Falls back to plain on non-secure context (http). Demo only.
  - Full state (events with payloads, quests, progress, all personal data) exported.
  - No passphrase derivation (e.g. no PBKDF2).
- **Gaps vs White Paper**:
  - Principle 2/4/5: Missing user-key encryption, e2e for exports/backups, lifecycle protection.
  - No "unweave" (secure full delete beyond modelContext.delete).
  - Inference risk: aggregates + linkedThreads can leak relational patterns (CareKin family data + Self goals).

**Semgrep**: Clean (no hardcoded secrets, injections detected in auto rules). Manual patterns found the above.

### Network, Externals & Leaks
- **Swift**: Core claims "no network in core", "local-only". Confirmed via searches (no fetch/URLSession/http except potential in previews). TimelineService/InsightGenerator purely on-device rules. Prints are local-only.
- **PWA**:
  - **External CDNs** (major privacy leak):
    - `<script src="https://cdn.tailwindcss.com">`
    - Font Awesome CDN
    - Google Fonts (@import Inter + Playfair)
  - These send IP, user-agent, referer on every load. Violates "all data remains local", "Privacy by Design", "no leaks".
  - No CSP, no SRI hashes.
  - innerHTML used extensively for dynamic content (XSS risk if untrusted data, though local).
- **Other**:
  - Settings links to "about:blank".
  - No telemetry but future "optional external model" noted as "stubbed disabled" in docs (but not fully removed in comments).
  - Web has "Weaver Pro" upsell (demo).

### Consent Flows
- **Minimal / absent**:
  - OnboardingView.swift: Informational pages mentioning "Privacy by Design" / "All local SwiftData. ... No cloud, no training". No checkboxes, no explicit "I consent to local storage of my life events", no "acknowledge sensitive data".
  - Settings: Descriptive text + destructive "Clear All" with basic .alert confirm. No granular (e.g. "clear only Self thread", "export without stories").
  - PWA: `confirm()` for clear/export (weak). No settings for privacy toggles.
  - No purpose limitation UI, no "share ripple?" prompts, no retention policy (e.g. auto-prune >90 days).
  - Per white paper: "cross-domain data flows require explicit, granular consent", "UI affordances make privacy visible".
- **Deletion/Portability**: Clear works (deletes models) but no confirmation of what/scope. Export incomplete → not portable.
- **No dark patterns**: Good intent, but missing affordances.

### Other Privacy Issues
- Data minimization: Full payloads stored and searchable/visible in History.
- No audit log of accesses/exports (local only).
- Device loss: No remote wipe concept.
- Web vs Native: PWA easier to inspect/exfil.
- Hermes-side (from prior audit): Not in scope here, but OneWeave data in sessions would need redaction.

## 2. Code Quality Gaps
### Compile & Runtime Bugs (Will Not Build/Run Cleanly)
- **Inheritance**: 
  - StewardshipThread.swift:5: `final class StewardshipThread: Thread {` 
  - But Thread.swift defines only `protocol ThreadProtocol {}` (no `class Thread`). 
  - Other threads correctly use `ThreadProtocol` (BasicSelf, CareKin, Meaning).
  - → Compile error.
- **Method Signature Mismatches (DataSeeder + impl)**:
  - DataSeeder.swift:70: `st.addSubscription("Spotify", monthlyCost: 10.99, ...)` 
    - Def (StewardshipThread.swift:17): `addSubscription(_ name: String, cost: Double, ...)`
  - DataSeeder.swift:71: `st.detectLeak(serviceName: "unused-app", estimatedMonthlySavings: 9.99, service:..., context:...)`
    - Def: `detectLeak(serviceName: String, reason: String, savingsAmount: Double = 0.0, ...)`
    - Missing `reason`, wrong label.
  - Seeder also calls other methods that mostly match, but these break seeding.
- **Missing Properties**:
  - CompassView.swift:28-29: `st.savingsSuggestions` (and `.first!`)
    - StewardshipThread has `recentInsights`, `leaks`, `totalPotentialSavings` — **no `savingsSuggestions`**.
    - → Runtime crash or nil.
  - Other potential: `savingsSuggestions` referenced only here.
- **API Inconsistencies (State Machine)**:
  - AppStateMachine.swift:52: `func transition(on event: TimelineEvent, context: LifeContext)`
    - TimelineService.swift:38: `stateMachine.transition(on: event)`  ← missing arg.
    - CompassView.swift:150 and OneWeavePrototype.swift: many calls pass `context: ...`
    - Inside transition: `context` param **never used** (logic duplicated in LifeContext.applyStateTransition).
  - Duplicate transition logic across files.
- **Export Stubs**:
  - SettingsView.swift: exportAllData() → hard-coded text + "See History...". No JSONEncoder, no full model dump.
  - Similar in ThreadDetailView.
  - Claims in IMPLEMENTED_FEATURES.md / README: "real JSON export", "full", "user-controlled export" overstated.
- **Other**:
  - Many `try?` swallowing errors.
  - Magic strings for event types ("leak_detected", "goal_added") everywhere — brittle.
  - Long methods, some commented debug prints left in (TimelineService).
  - Single LifeContext assumption (queries .first).
  - No @Model attributes for indexes/unique beyond UUID in events.
  - Preview code duplicated.

### Style, Structure & Maintainability
- Good: Modular threads (mostly), protocol, @Observable service, event-driven core, environment injection.
- Issues: Prototype.swift overlaps main app logic (demo harness). Large monolithic PWA (one 80k file). Inconsistent naming (Thread vs ThreadProtocol).
- No tests visible in sources (XCTest?).
- Seeder has realistic but hardcoded personal data.
- UI: Heavy use of @Query + fetch inside views (perf?); some state duplication.

**Semgrep/Scans**: No vulns flagged. Grep for "TODO|stub|placeholder" mostly in docs/comments claiming "no stubs".

### Docs vs Reality Gap
- IMPLEMENTED_FEATURES.md, WHITE_PAPER.md, README: "Full End-to-End Production-Ready", "no code placeholders/stubs", "real export", "20 Swift files", "Security/Privacy Review ... No leaks (grep/scan clean)".
- Reality: Bugs above, incomplete export, missing props, overstated privacy (no encryption).
- Good coverage of philosophy, user journeys, gamification spec.
- PRIVACY_AUDIT... is Hermes/env focused, not app code.

## 3. Completeness Gaps for Full Production
**What's Solid**:
- Event propagation + cross-thread ripples (TimelineService + LifeContext).
- State machine (AppState enum + transitions, visible in UI with colors/haptics).
- On-device insights (InsightGenerator rule-based, no external calls).
- UI: Compass rings, energy, history search, threads overviews, settings toggles (basic).
- Local persistence + seeding + clear.
- Calm UI elements (glass, animations per white paper).
- Philosophy integration.

**Missing / Incomplete**:
- **Export/Backup/Import**: Stub → must be full serializable JSON (with version, schema) + roundtrip.
- **Encryption**:
  - Export: Passphrase-based (CryptoKit for Swift, WebCrypto + PBKDF2 for web).
  - At-rest: Optional user key or better iOS integration.
- **Consent & Controls**:
  - Granular toggles (cross-ripples? full payload storage?).
  - Explicit acks in onboarding.
  - Privacy dashboard (data size, last clear/export, "forget thread X").
- **Data Handling**:
  - Redaction on export/insight (optional keywords).
  - Validation, schema migration for models.
  - Secure delete (overwrite?).
  - Limits on history (e.g. 1000 events, auto-archive).
- **Web/PWA**:
  - Self-contained (inline Tailwind? or local; system fonts/icons).
  - Better storage (IndexedDB + encryption).
  - PWA manifest, icons, offline worker (basic).
  - No "Pro" without real backend (or local-only unlock).
- **Prod Engineering**:
  - Full Xcode project structure, assets, Info.plist (FileProtection), entitlements.
  - Unit/UI tests, snapshot tests.
  - Error handling, accessibility (VoiceOver for state/ripples).
  - Versioning, migration.
  - Threat modeling / pen-test notes.
  - Compliance: privacy policy UI, GDPR "right to be forgotten" button.
  - Optional: on-device ML (Apple Intelligence) with explicit consent.
- **Other**:
  - No import of prior exports.
  - Duplicate PWA files (oneweave-web + deliverables).
  - No build scripts or CI artifacts.
  - State machine in AppStateMachine vs LifeContext not fully synced in all paths.

**Positive Notes**: "All local" repeated consistently. No hard secrets. Good use of SwiftData for queries.

## 4. Specific Findings by File/Component
- **TimelineEvent.swift / LifeContext.swift / TimelineService.swift**: Core good; raw payloads, privacyLevel unenforced, prints, context init assumptions.
- **StewardshipThread.swift + DataSeeder.swift + CompassView.swift**: Highest bug density (inheritance, calls, props).
- **SettingsView.swift / ThreadDetailView.swift**: Export incomplete; clear ok with alert.
- **OnboardingView.swift**: Good info, zero interactive consent.
- **AppStateMachine.swift**: Logic sound but API broken/inconsistent; unused param.
- **PWA (both HTMLs)**: Functional demo with canvas/tapestry, quests, badges, simulate. But storage weak, crypto flawed, externals.
- **White papers / specs**: Excellent requirements; code doesn't meet encryption/consent/export.
- **Semgrep**: 0 findings on auto (good baseline).

## 5. Recommendations & Prioritized Fixes for Production
**Priority 0 (Blockers - Fix Before Any Build)**:
1. Fix compile bugs (inheritance, signatures, missing props, transition API).
2. Implement **real export** (JSONEncoder of all models) + **basic encrypted export**.
3. Add **explicit consent** in onboarding + settings.

**Priority 1 (Privacy Hardening)**:
- CryptoKit AES-GCM export with passphrase (salt + iterations).
- Remove/bust CDNs in PWA; inline or use SF Symbols equivalent.
- Add payload redaction helper (strip names/dates? or keywords).
- Document iOS data protection; set in project.

**Priority 2 (Completeness)**:
- Full import + validation.
- Granular consent toggles + retention.
- Tests + error paths.
- Update docs to match code (or vice versa).
- Self-contained PWA.

**Priority 3**:
- Threat model doc.
- Keychain integration.
- PWA manifest + better offline.

**General**:
- Treat sensitive data: minimize what goes into payload (use IDs + separate secure notes?).
- For web: consider migrating to proper framework or Electron/Tauri with secure storage.
- Regular audits (add to cron as in prior Hermes audit).
- "Privacy by Design" section in Settings should link real controls.

## Suggested Patches
See accompanying patches or apply via:
- Use `patch` tool or manual for Swift fixes (examples below).
- For encryption: add CryptoKit import + functions.
- Full diffs in follow-up or PATCHES/ dir.

**Critical Bug Fixes (examples; apply these first)**:

1. StewardshipThread inheritance + add savingsSuggestions alias or populate recentInsights consistently.
2. Update DataSeeder calls.
3. Fix Compass ref.
4. Make transition context optional.
5. Upgrade exportAllData to real export.

Example patch for export (improved):
```diff
- var export = "OneWeave Full Export\n\n"
+ let encoder = JSONEncoder()
+ encoder.outputFormatting = .prettyPrinted
+ if let data = try? encoder.encode(contexts + allEvents...) { ... }
```

See detailed patches in generated files or run tool calls.

## Appendix: Commands & Evidence
- Structure: `find ... | sort`
- Scans: `search_files` for storage/encrypt/fetch/consent + TODOs + prints.
- Static: `semgrep --config=auto` → 0 results.
- Reads: Multi-file, offset reads on large PWA/Swift (~20 files fully or sectioned).
- White paper alignment: Cross-referenced 7 PbD principles.

**Status**: Audit complete. Codebase has strong bones but requires immediate fixes for bugs + privacy features to approach production. All local analysis.

Next: Apply patches, re-audit, generate encrypted export impl.
