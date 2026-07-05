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