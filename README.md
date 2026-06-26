# OneWeave

**Life as One Interconnected Journey.**

OneWeave is a calm, privacy-first iOS app that models your life as four fluid Life Threads (Self, Stewardship, Care & Kin, Meaning & Legacy). Every action creates visible ripples across domains on the Journey Compass — with dynamic energy bars, trends, and an "Active Ripples" summary.

## Current Status (2026-06-25)
- 17 Swift files, SwiftUI + SwiftData (iOS 18+ ready)
- 5-tab navigation: Compass | Threads | History | Settings | Demo
- Fully event-driven interconnections
- Production-grade foundation: local-only data, clear data flow, empty states, privacy emphasis
- See MARKETING.md for positioning, copy, and visuals

## Quick Start (for developers)
1. Drop `Sources/OneWeave/` into a new SwiftUI project with SwiftData.
2. Run the app — Demo tab seeds journeys; switch tabs to explore.
3. Quick Capture in Compass or thread actions create ripples.

## Key Implemented Features
(See IMPLEMENTED_FEATURES.md for the full detailed list)

- **Journey Compass**: Dynamic rings sized by activity, per-thread energy progress bars + trend indicators, Active Ripples section, live insights + real-world bridges, quick capture with intelligent routing.
- **Life Threads**: Rich models with processEvent ripples, summaries, habits/streaks (Self), leak detection/savings (Stewardship), task load + IRL (CareKin), stories/legacy (Meaning).
- **Interconnections**: TimelineService emits events that update LifeContext, Compass, History, and linked threads.
- **History & Overview**: Full ripple timeline + tappable thread cards with live summaries and weave demos.
- **Settings**: Privacy controls, one-tap clear all data, on-device focus.
- **Demo**: Multiple realistic journey simulations (busy season, leaks, care load, resource redirects).

## Privacy & Philosophy
All data stays local (SwiftData). No cloud by default. Designed for calm attention and systems thinking. Global best practices for privacy and no-training are baked in.

## Next Steps Toward Production
- Deeper per-thread UIs (habit lists, subscription manager, task board)
- Charts, filters, better launch seeding
- Export, external model opt-in (consent + redaction)
- Full Xcode project, tests, App Store assets

## Marketing
See `MARKETING.md` for taglines, App Store copy, benefits, target audience, and feature highlights.

## Generated Visuals
- Compass screen mockup (portrait)
- Marketing hero illustration (landscape)

Built with multi-agent iteration (delegate_task + external models) + Spec Kit process.

---

## Packaging, PWA & Legacy (Phase 8 notes)
- **Native iOS**: Primary target. Drop `Sources/OneWeave/` into Xcode SwiftUI + SwiftData project (iOS 18+). Model container pre-wired for gamification (LifeContext, WeaveQuest, Threads, Events). See LAUNCH_CHECKLIST.md for App Store / TestFlight prep.
- **Web PWA**: Basic support in `web-pwa/` (manifest.json for installable, sw.js for offline cache). Full demo parity in `hermes-workspace/deliverables/oneweave-pwa.html` (and oneweave-web/index.html) includes loom/tapestry canvas, quests, reflection, essence/streak/mastery HUD, state visuals. **Notes**: Current HTML uses external CDNs (privacy consideration); production packaging should inline styles/scripts/assets or use local equivalents for no-CDN offline. Service worker basic; enhance for full IndexedDB state sync with gamif fields. Serve statically (e.g. GitHub Pages, Vercel) for legacy access.
- **Legacy exports/compat**: Settings export now includes full gamification data (essence, level, masteryTiers, streaks+grace, completed/active quests, ledger, reflections). Structured for backward compat (pre-gamif data loads with defaults: 0 essence, empty tiers/quests). No full import UI yet (post-MVP); export JSON block + text summary ensures portability across versions.
- **Other Phase 8**: Personalization (local prefs only, no cloud), high-level Widgets/Intents (post-MVP: WidgetKit for harmony/quests, App Intents). See `.specify/specs/002-gamification/tasks.md` and IMPLEMENTED_FEATURES.md for details.
- All packaging emphasizes local-first, privacy (no telemetry), calm design per white paper.

*One interconnected journey. See the ripples.*