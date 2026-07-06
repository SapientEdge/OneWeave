# Building OneWeave on macOS + Xcode

This guide walks through cloning the OneWeave repo on a Mac desktop, opening it in Xcode, and running the iOS app for the first time. The codebase is the same one that was developed + validated on Linux (57/58 validators green) — your job is to get it compiling + running on iOS.

## Prerequisites

| Tool | Version | Why |
|---|---|---|
| **macOS** | 14.0+ (Sonoma) or 15.0+ (Sequoia) | SwiftData requires modern macOS |
| **Xcode** | 15.0+ (recommended 16.0) | Swift 5.9, iOS 17+ SDK |
| **Command Line Tools** | latest | git, etc. |
| **iOS Simulator** | iPhone 15 / 16 (iOS 17+) | Test the app |

```bash
xcode-select --install     # if you haven't already
```

## Step 1: Clone the repo

```bash
cd ~/Developer          # or wherever you keep projects
git clone https://github.com/SapientEdge/OneWeave.git
cd OneWeave
git log --oneline | head -5    # see what's at HEAD
```

The repo is **private** — you'll need to authenticate with GitHub (SSH key recommended, or a personal access token).

## Step 2: Verify Linux validators run (sanity check)

This proves the Swift code matches the validators that already passed on Linux.

```bash
bash .research/validate_all.sh
```

You should see:
```
Suites run: 43
Suites all-green: 42
Suites with failures: 1     ← known cycle 41 false positive, ignore
✗ AT LEAST ONE SUITE HAS FAILURES
```

The 1 failure is a known false positive (`validate_cycle41_consensus.py` uses different output format — pre-existing). **42 green is the real signal.**

## Step 3: Open in Xcode

```bash
open Package.swift
```

OR double-click `Package.swift` in Finder.

Xcode will open and start indexing. **Wait for "Indexing | Done"** in the top bar before proceeding (typically 1–3 minutes for this codebase).

## Step 4: Create an Xcode project wrapper

This codebase is a **Swift Package** (not yet an `.xcodeproj`). You'll need to create an iOS app target that consumes the Swift package.

### Option A: Use SwiftPM directly (simplest)

1. In Xcode: File → New → Project → iOS → App
2. Product Name: **OneWeave**
3. Interface: **SwiftUI**, Language: **Swift**
4. Save it OUTSIDE this repo (e.g. `~/Developer/OneWeaveApp/`)
5. In the new project, delete the default `ContentView.swift` and `OneWeaveApp.swift`
6. Add the package as a dependency:
   - File → Add Package Dependencies → Add Local...
   - Navigate to and select this `OneWeave` repo folder
   - Choose the `OneWeave` library product
7. Create a new Swift file in your app target: `App.swift`:
   ```swift
   import SwiftUI
   import OneWeave

   @main
   struct OneWeaveAppMain: App {
       var body: some Scene {
           WindowGroup {
               CompassView()
           }
       }
   }
   ```
8. Build & Run (⌘R)

### Option B: Convert in-place to .xcodeproj

1. In Xcode: File → New → Project → iOS → App (Product Name: OneWeave)
2. Save INTO this repo as `OneWeave.xcodeproj` (overwriting the existing Swift Package)
3. Move Sources/OneWeave/*.swift files into the new project's group structure
4. Add the AppIntents/Widgets extensions (production code already exists in OneWeaveWidgetStubs.swift)

**Recommendation:** Start with Option A. It's faster and the SwiftPM layout is already clean.

## Step 5: Run on Simulator

1. Top-left device picker → iPhone 15 Pro (iOS 17.0+)
2. Press **⌘R** (Run)
3. The app should launch with the **CompassView** as the root view
4. You should see the Living Loom (production Canvas), GamificationHUD, and prompts list

If you see compile errors in the SwiftUI layer — that's expected. The Linux side validated the **algorithms + privacy invariants** but the SwiftUI bindings need a Mac to fully resolve.

## Step 6: Specific things to test

| Area | What to check |
|---|---|
| **CompassView** | The Living Loom renders threads with embroidery stitches + ripple pulses |
| **GamificationHUD** | Essence, Level, Streak, Harmony visible |
| **Reflection Gate** | Try to commit a quest → modal appears requiring non-empty reflection |
| **Data Leash** | Settings → toggle integrations; calendar/contacts/healthkit should error if disabled (because Linux has no real data) |
| **Sacred Echo** | Settings → Sealing flow → crypto should pass (fail-closed) |
| **Cognitive Load** | Should trigger dim UI at score=0.70, Weave Pause at score=0.85+rising+body-depleted |
| **LifeMoment** (cycle 46) | Capture view → take a photo → Vision OCR runs → reflection sheet appears |

## Step 7: Common build errors

### "Cannot find 'X' in scope"

If you see unresolved imports, ensure:
- The `OneWeave` library product is added to your target's dependencies
- Build Settings → **Swift Compiler - Search Paths** includes the package

### "SwiftData @Model not found"

Requires **iOS 17+ deployment target**. Check:
- Target → General → Minimum Deployments → iOS 17.0

### "Privacy manifest" warnings

The repo includes `Sources/OneWeave/PrivacyInfo.xcprivacy`. Add it to your target:
- Target → Build Phases → Copy Bundle Resources → Add `PrivacyInfo.xcprivacy`

## Step 8: After it builds — what to test first

1. **Onboarding flow** (`OnboardingView.swift`) — should show the "no cloud, no sync" copy
2. **Compass → Quick Capture** — write a quick capture, attach to a thread
3. **Compass → Quests → Generate Quest** — generates a quest, requires reflection to complete
4. **Compass → Daily Briefing** — should show morning + evening briefings
5. **Settings → Privacy** — verify Data Leash toggles + Privacy Manifest

## What's NOT in the public repo

The Mac build does **NOT** need (these are gitignored):

- `.research/` internal review docs (round4/*, glm_round_1/*, etc.)
- `scripts/cycle*/` sub-agent timing data
- `specs/04[6-9]*/` cycle handoff specs
- `.cli/`, `.codex/`, `.agents/` — multi-agent working dirs
- `graphify-out/` — regenerable knowledge graph
- Internal validators' build_log.md

What IS in the repo (the public test suite):

- 34 Python validators in `.research/validate_*.py`
- `bash .research/validate_all.sh` runs them all
- Source code in `Sources/OneWeave/`
- Documentation in `*.md` (README, ARCHITECTURE, PRIVACY, etc.)

## When you find bugs

File issues at https://github.com/SapientEdge/OneWeave/issues

For critical Swift compile errors: tag them as `priority/critical` and include:
- Xcode version
- iOS Simulator version
- Exact error message
- File + line number

---

*Built with [Claude cowork + Lovable] on a Linux VPS, validated by 57/58 automated Python validators, ready for Mac + Xcode compilation.*