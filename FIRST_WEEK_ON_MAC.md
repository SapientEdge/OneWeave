# OneWeave — Dan's First Week on Mac

*Human-readable checklist for taking the Linux-validated OneWeave codebase and shipping it on the App Store. Use this alongside `CLAUDE_COWORK_BRIEF.md` (the brief for Claude cowork).*

---

## What you have right now (Linux, before Mac)

- **55 Swift files** in `Sources/OneWeave/` (~14,800 lines)
- **16 Python validation suites** in `.research/validate_*.py` (525+ tests, all green)
- **OneWeaveAPI.swift** catalog of every public type
- **PRIVACY.md** documenting the 5 privacy gates
- **MANIFEST.md** with every file + line count + purpose
- **VALIDATION_REPORT.md** with current pass/fail status
- **MARKET_RESEARCH_ROUND_3.md** positioning analysis
- **TIER_B_PLAYBOOK.md** the 8-phase Mac build plan
- **AGENT_SQUAD_PROMPTS.md** multi-agent dispatch recipes

Run `bash .research/validate_all.sh` any time to confirm 16/16 suites pass.

---

## Day 1 (Saturday) — Mac setup

**Goal: Mac is ready, repo is cloned, you have signed into GitHub.**

### 1.1 Get a Mac capable of Xcode 16+
- MacBook Pro M1/M2/M3/M4 (any from 2020+) — recommended
- macOS 14 Sonoma or 15 Sequoia required
- 16 GB RAM minimum, 32 GB recommended
- If you don't have a Mac, options:
  - **MacStadium** ($50-100/month, dedicated Mac)
  - **Crunsh** (cheaper shared hosting)
  - Borrow/rent for the launch phase

### 1.2 Install the toolchain
- [ ] **Xcode 16+** from App Store (free, ~12 GB)
- [ ] **Command Line Tools**: `xcode-select --install`
- [ ] **Homebrew**: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- [ ] **Git**: preinstalled with Xcode
- [ ] **GitHub CLI** (optional but useful): `brew install gh`

### 1.3 Create a GitHub account + Apple Developer account
- [ ] GitHub: https://github.com (free for private repos)
- [ ] Apple Developer Program: https://developer.apple.com/programs/enroll/ (**$99/year** — required for App Store submission, NOT required for development)
- [ ] If you're not ready to pay Apple yet, you can develop and use TestFlight with a free Apple ID (but App Store submission requires the paid enrollment)

### 1.4 Set up authentication (your choice)

**Option A: Personal Access Token (HTTPS) — easiest**
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `repo` scope
3. Save it somewhere safe (Keychain, password manager)
4. When pushing for the first time, use the token as the password

**Option B: SSH key — better long-term**
1. On Mac: `ssh-keygen -t ed25519 -C "your@email.com"`
2. Press Enter for default location, set a passphrase
3. Copy public key: `pbcopy < ~/.ssh/id_ed25519.pub`
4. GitHub → Settings → SSH and GPG keys → New SSH key → paste
5. Test: `ssh -T git@github.com`

### 1.5 Clone the OneWeave repo
```bash
mkdir -p ~/projects
cd ~/projects
# (replace with your actual repo URL after you push from Linux)
git clone https://github.com/YOUR_USERNAME/oneweave.git
cd oneweave
bash .research/validate_all.sh
# Should print "✓ ALL SUITES PASS" with 16 suites
```

If you see failures, the Linux machine's push may have been incomplete. See Phase 4 in the Linux-side brief.

---

## Day 2 (Sunday) — Xcode project skeleton

**Goal: app builds and runs in iOS Simulator.**

### 2.1 Create the Xcode project
- [ ] Open Xcode → File → New → Project
- [ ] **iOS** → **App** template
- [ ] Product Name: **OneWeave**
- [ ] Team: (your Apple ID or skip for now)
- [ ] Organization Identifier: `com.oneweave` (matches App Group prefix)
- [ ] Interface: **SwiftUI**
- [ ] Language: **Swift**
- [ ] Storage: **SwiftData** ✓
- [ ] Save into `~/projects/oneweave/Xcode/`

### 2.2 Move Swift files into Xcode
- [ ] In Xcode, right-click `OneWeave` group → Add Files to "OneWeave"...
- [ ] Select all 55 `.swift` files from `Sources/OneWeave/` (don't include `.research/`)
- [ ] Check "Copy items if needed" → OFF (we want them referenced)
- [ ] Check "Create groups"
- [ ] Click Add

### 2.3 Configure deployment target
- [ ] Select OneWeave project → OneWeave target → General
- [ ] Minimum Deployments: **iOS 17.0** (or higher if you have only newer Xcode)

### 2.4 Fix any compile errors
This is where the rubber meets the road. Common errors you'll hit:

| Error | Fix |
|-------|-----|
| "Cannot find type 'Foo' in scope" | Check that the file is added to the target. Look at the File Inspector (right pane). |
| "Type 'X' does not conform to protocol 'Codable'" | Check enum associated values; they need explicit Codable conformance. |
| "@MainActor isolation" | Wrap calls in `Task { @MainActor in ... }` |
| "Missing import" | Add at top of file. Common: `Foundation`, `SwiftData`, `CryptoKit`, `Combine`, `SwiftUI` |
| "Cannot infer context" | Add explicit type annotations |
| "Concurrent access" | Add `@MainActor` to the offending type |

**Expect 30-60 compile errors on first build.** Most are mechanical fixes. The 3 multi-agent review rounds already caught the deep logic bugs.

### 2.5 Build and run
- [ ] Select an iOS Simulator (iPhone 16 Pro recommended)
- [ ] ⌘B (Build)
- [ ] ⌘R (Run)
- [ ] App should launch in the simulator

### 2.6 Verify the prototype harness runs
- [ ] Tap the **Demo** tab in the app
- [ ] Tap each demo button to seed sample data
- [ ] Verify timeline populates, threads show activity, insights appear

---

## Day 3 (Monday) — App Group + Widget Extension

**Goal: data syncs between main app and widget, widget renders.**

### 3.1 Add App Group
- [ ] Select OneWeave target → Signing & Capabilities → **+ Capability** → **App Groups**
- [ ] Add group: `group.com.oneweave`
- [ ] **Repeat for the widget target** (when you add it)

### 3.2 Add Widget Extension target
- [ ] File → New → Target → **Widget Extension**
- [ ] Product Name: **OneWeaveWidget**
- [ ] Embed in app: OneWeave
- [ ] Activate scheme when prompted
- [ ] Add the same App Group `group.com.oneweave` to the widget target

### 3.3 Wire OneWeaveSnapshotStore
- [ ] The `OneWeaveWidgetStubs.swift` file contains the widget structures
- [ ] Implement the `TimelineProvider` (3 methods: `placeholder`, `getSnapshot`, `getTimeline`)
- [ ] Read from `UserDefaults(suiteName: "group.com.oneweave")`
- [ ] Verify widget renders in the Today view / Home Screen

### 3.4 Test App Group sync
- [ ] In main app, complete a quest or write a reflection
- [ ] Check that the widget's `getTimeline` returns the updated data within 30 seconds
- [ ] (Apple rate-limits widget refreshes to ~40-70/day)

---

## Day 4 (Tuesday) — App Intents + P2P transport

**Goal: Siri shortcuts work; P2P basics in place (stubbed for now).**

### 4.1 App Intents
- [ ] Verify `LogWeaveIntent`, `CompleteQuestIntent`, `ShowHarmonyIntent` are in OneWeaveApp.swift
- [ ] Run in simulator, ask Siri "Log a reflection" → confirm SiriKit routes correctly
- [ ] Add `AppShortcutsProvider` so intents appear in Shortcuts app

### 4.2 P2P transport (basic)
- [ ] Open `P2PWeaveShare.swift`
- [ ] The `sendViaWebRTC` function is a stub. For now, replace with Bonjour local discovery using `NWBrowser`
- [ ] Build a small in-simulator test: two simulators can see each other
- [ ] Real WebRTC via CocoaPods (`pod 'GoogleWebRTC'`) — defer this until App Store submission

### 4.3 Sacred Echo crypto (production Keychain)
- [ ] On device, the `SacredEchoCipher.vaultSeed()` path uses Keychain
- [ ] On simulator, it uses the test seed (correct)
- [ ] Verify on a real device: open Xcode → Window → Devices → select your iPhone → run → check Console for any "vault seed" warnings

---

## Day 5 (Wednesday) — Real device + XCTest

**Goal: app runs on a real iPhone, basic tests pass.**

### 5.1 Set up a real device
- [ ] Plug in your iPhone → Trust Mac → Xcode detects it
- [ ] Select your iPhone as the run target (not Simulator)
- [ ] If your Apple Developer account isn't enrolled: free provisioning may work for personal testing
- [ ] If not: sign up for Apple Developer Program ($99/year) before continuing

### 5.2 Add XCTest target
- [ ] File → New → Target → **Unit Testing Bundle**
- [ ] Name: **OneWeaveTests**
- [ ] Add to project

### 5.3 Port critical tests
The Linux Python validators cover 525+ tests. For now, port the 30-50 most critical Swift tests:
- Sacred Echo crypto round-trip
- Weave Pause gate (empty vs non-empty reflection)
- Data Leash policy (categories + currentLeash read)
- Cognitive Load normalization (boundary cases)
- Quick Capture classifier (the 5 destination cases)

The full set of Python tests stay in `.research/validate_*.py` — those test the algorithm logic, not the Apple-runtime-dependent types. Run them on Linux CI (or manually before commits).

### 5.4 Run on real device
- [ ] Test: write a reflection, complete a quest, open a Sacred Echo (use a 1-day unlock for testing)
- [ ] Test: trigger Weave Pause by simulating high cognitive load
- [ ] Test: share something via Family Pod (add yourself + a fake member)
- [ ] Verify widget shows updated data

---

## Day 6 (Thursday) — Polish + App Store assets

**Goal: app looks good, screenshots are taken, ASO is set.**

### 6.1 Visual polish (the hard part)
The Linux side has 55 Swift files but the UI is intentionally minimal. The Mac side adds:
- Real color palette (the design system is in CompassView, LoomGeometry)
- Proper typography (Dynamic Type support)
- Empty states with thoughtful copy
- Onboarding (3-screen welcome flow)

Design resources:
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- iOS 27 design trends (search web)

### 6.2 Take screenshots
- [ ] Run app on iPhone 16 Pro simulator (1290 × 2796 px)
- [ ] Use `xcrun simctl io booted screenshot` to capture
- [ ] Capture: Compass (Loom), Threads, Family Pod, Cognitive Load, Sacred Echo, Invisible Mentor
- [ ] Repeat for iPhone 15 Pro, iPhone SE (3rd gen) for older devices

### 6.3 App Store Connect metadata
- [ ] Go to https://appstoreconnect.apple.com
- [ ] My Apps → **+** → New App → iOS
- [ ] Bundle ID: `com.oneweave.OneWeave` (must match Xcode)
- [ ] SKU: `oneweave-001`
- [ ] Primary language: English
- [ ] Name: **OneWeave**
- [ ] Subtitle: **Life as one interconnected journey**
- [ ] Category: **Health & Fitness** (primary) + **Productivity** (secondary)
- [ ] Privacy policy URL: (you'll need to host this — GitHub Pages works)
- [ ] Description: (use MARKET_RESEARCH_ROUND_3.md positioning)
- [ ] Keywords: `journal, private, life, mood, relationships, decisions, focus`
- [ ] Screenshots: 3-10 per device class
- [ ] App icon: 1024×1024 PNG (no transparency, no rounded corners — Apple applies them)

### 6.4 Privacy nutrition labels
- [ ] App Store Connect → App Privacy
- [ ] **Data Not Collected** if you don't use analytics (recommended for v1)
- [ ] Or declare exactly what you DO collect (HealthKit read access, etc.)

---

## Day 7 (Friday) — TestFlight + submit for review

**Goal: app on TestFlight, beta testers invited, App Store submission submitted.**

### 7.1 TestFlight internal testing
- [ ] Xcode → Product → Archive
- [ ] Wait for archive (~5-10 min)
- [ ] Organizer → Distribute App → App Store Connect → Upload
- [ ] Wait for App Store Connect to process the build (~10-30 min)
- [ ] App Store Connect → My Apps → OneWeave → TestFlight
- [ ] Add internal testers (your email is auto-added)
- [ ] Submit for beta review (fast, usually hours)
- [ ] Once approved, install TestFlight app on your phone and download

### 7.2 External beta testing (optional)
- [ ] Add up to 10,000 external testers via public link
- [ ] Best channels: r/privacy, r/sideproject, Hacker News, Product Hunt "Upcoming"
- [ ] Provide a feedback mechanism (Typeform, email)

### 7.3 App Store submission
- [ ] App Store Connect → OneWeave → version 1.0
- [ ] Select the build you uploaded
- [ ] Provide export compliance info (encryption used: yes, but qualifies for exemption since not used for https only)
- [ ] Submit for review
- [ ] Typical review time: 24-48 hours

### 7.4 If Apple rejects
Common reasons:
- Privacy nutrition label inconsistent with actual behavior
- Missing demo account for testing review features
- Privacy policy URL doesn't work
- Crash on launch in their test environment
- In-app purchase doesn't restore correctly

Fix the issue, increment build number, resubmit. Most rejections get resolved in 1-2 cycles.

---

## After launch (Week 2+)

### Week 2: Listen + iterate
- [ ] Check TestFlight feedback daily
- [ ] Check App Store reviews (1.0 launches usually get a flood)
- [ ] Fix top 3 most-mentioned bugs
- [ ] Submit 1.0.1 with fixes
- [ ] Public launch on Product Hunt, Hacker News

### Week 3-4: Growth experiments
- [ ] ASO experiments (different keywords)
- [ ] Press outreach (TechCrunch, The Verge, MacStories for iOS launches)
- [ ] Reddit posts in relevant subs (genuine participation, not spam)
- [ ] Twitter/X presence (build-in-public narrative)

### Month 2: First paid tier
- [ ] Decide: one-time $19.99 or subscription
- [ ] Implement via StoreKit 2 (Swift)
- [ ] Test purchase flow with sandbox account
- [ ] Submit with new tier

---

## Total time estimate

| Phase | Time (realistic) |
|-------|------------------|
| Day 1 (Mac setup) | 3-4 hours |
| Day 2 (Xcode skeleton) | 6-8 hours (most compile error fixing) |
| Day 3 (App Group + Widget) | 4-6 hours |
| Day 4 (App Intents + P2P) | 6-10 hours (P2P transport is complex) |
| Day 5 (Real device + XCTest) | 4-6 hours |
| Day 6 (Polish + assets) | 6-8 hours |
| Day 7 (TestFlight + submit) | 3-4 hours |
| Apple review | 24-48 hours (waiting) |
| **Total focused work** | **30-44 hours** |
| **Total elapsed** | **2-3 weeks** (depending on real-life schedule) |

---

## Real risks (don't ignore these)

1. **Compile errors**: Could be 100+ on first build. Plan for 6-8 hours of error fixing. Don't panic — they're mechanical.
2. **SwiftData migration**: Real-device installs may behave differently than simulator. Test on physical device before submitting.
3. **App Store rejection**: Most apps get rejected at least once. Don't get discouraged. Read the rejection carefully, fix exactly what they said, resubmit.
4. **Privacy policy**: Apple requires this URL to work and accurately describe your data practices. Use PRIVACY.md as a starting point.
5. **No backup plan for CocoaPods**: If you add WebRTC via CocoaPods and it doesn't build, that's a multi-hour debugging session. Consider skipping WebRTC for v1.
6. **iCloud sync**: Built but not fully tested. iCloud sync is notoriously fragile. Consider shipping without iCloud sync for v1.

---

## Honest assessment

The Linux work is **substantially complete and validated**. The Mac work is **standard iOS development**, not invention. You'll hit bugs, but they're not architectural — they're the kind of bugs every iOS app hits.

**Realistic outcome**: with focused work, you can have a TestFlight build in 1-2 weeks. App Store launch in 3-4 weeks.

**What makes this app distinctive** (not the work itself, but the market position):
- Privacy-first in a market where everyone has cloud AI
- Anti-social family (Family Pod is unique)
- Sacred Echo Vault has no competitor
- Decision Log with mentor citation has no competitor

**What could go wrong**:
- Apple launches a competing Life OS feature in iOS 28 (possible but ~1 year out)
- Users don't find the privacy-first message compelling enough
- The Cognitive Load / Weave Pause concept is too abstract for mainstream users

**What I'd do next** (after shipping v1):
- Get 1000 beta users
- Survey them on what's missing
- Build the top 3 missing features
- Iterate

---

## Resources

- **OneWeave code**: `/Users/YOU/projects/oneweave/`
- **Validation harness**: `bash .research/validate_all.sh`
- **Market research**: `.research/MARKET_RESEARCH_ROUND_3.md`
- **Privacy threat model**: `PRIVACY.md`
- **Architecture overview**: `ARCHITECTURE.md`
- **Public API catalog**: `Sources/OneWeave/OneWeaveAPI.swift`
- **File inventory**: `MANIFEST.md`

— Hermes / MiniMax-M3, from Linux, June 2026