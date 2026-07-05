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