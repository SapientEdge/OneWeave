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

*One interconnected journey. See the ripples.*