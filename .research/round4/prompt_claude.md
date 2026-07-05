You are Claude Code (opus, max thinking). Production-readiness audit of OneWeave at /root/hermes-workspace/projects/oneweave.

SCOPE: Apple App Store submission readiness. iOS 17+ SwiftUI/SwiftData. Linux-built, Mac-handoff pending.

READ FIRST (in this order):
1. /root/hermes-workspace/projects/oneweave/ONEWEAVE_HANDOFF_2026-06-27.md (master entry)
2. /root/hermes-workspace/projects/oneweave/.specify/constitution.md (10 principles)
3. /root/hermes-workspace/projects/oneweave/.specify/specs/003-production-readiness/tasks.md (T075-T096 already added)
4. /root/hermes-workspace/projects/oneweave/.research/REVIEW_ROUND_3_NEMOTRON.md (Nemotron's 46 findings)
5. /root/hermes-workspace/projects/oneweave/.research/REVIEW_ROUND_3_CLAUDE.md (your own earlier review)
6. /root/hermes-workspace/projects/oneweave/Sources/OneWeave/LifeContext.swift (557 LOC, core @Model)
7. /root/hermes-workspace/projects/oneweave/Sources/OneWeave/SacredEcho.swift (658 LOC, crypto)
8. /root/hermes-workspace/projects/oneweave/Sources/OneWeave/iOSServiceIntegrations.swift (778 LOC, integrations)

YOUR FOCUS (different from Grok's specialization):
- Architectural completeness: what features are MISSING for a production Life OS app?
- Spec gaps: where does reality diverge from the constitution?
- Apple HIG compliance: notifications, accessibility (Dynamic Type, VoiceOver, Reduce Motion), SF Symbols, dark mode, Dynamic Island, App Intents for Siri
- Lifecycle edge cases: first launch, onboarding, schema migration failure recovery, backup/restore via iCloud (or refusal), scene phase transitions
- Privacy UX: consent screens, onboarding copy, in-app privacy dashboard beyond the 9 toggles
- Build/CI gaps that affect submission: code signing entitlements, App Store privacy nutrition labels, export compliance (BIS), data collection disclosure
- Onboarding flow: is the 74-LOC OnboardingView complete? what does first-launch feel like?
- Settings/About: version, build, acknowledgements, support URL, license
- Error handling: every async path needs a recovery UX, not just a print

OUTPUT (numbered, structured, max 2000 words):
A. Top 10 MISSING FEATURES (production-grade iOS Life OS standard)
B. Top 10 ARCHITECTURE GAPS (compilation/safety/performance)
C. Top 10 APPLE HIG COMPLIANCE GAPS
D. Top 10 SPEC/CONSTITUTION DRIFT POINTS
E. Build & submission readiness checklist (info.plist keys, entitlements, privacy labels)

Cite file:line where applicable. Mark each item [LINUX-FIXABLE] vs [MAC-NEEDED].
No re-listing of Nemotron's already-known findings (CLAUDE-R3-1..25) — assume integrated.
Be a senior engineer who has shipped privacy-first iOS apps, not a theorist.