# OneWeave Constitution v3.0 — DRAFT (Cycle 39 / T190)

**Status:** Draft amendment to v2.0
**Proposed:** 2026-06-28 (Cycle 39)
**Author:** OneWeave Linux build agent
**Source tasks:** T190, T191 — `.specify/specs/003-production-readiness/tasks.md` §Phase T16

This document amends v2.0 by adding an explicit, binding decision on
Private Cloud Compute / iCloud sync for OneWeave v1.0. The amendment
does **not** weaken any existing principle; it adds a concrete product
commitment that has been implicit in v2.0 §2 and §3 but was not
prominently stated.

---

## §11 — iCloud / Private Cloud Compute Sync (new, v3.0)

### §11.1 — Decision

**OneWeave v1.0 does NOT implement Private Cloud Compute (PCC) sync or
any other iCloud / CloudKit-backed mirroring of user data.**

This is a binding product commitment for the v1.0 ship target, not a
technical limitation that may quietly change later. Any future change
requires a constitutional amendment (v3.x or v4) AND an explicit
user-visible opt-in flow at runtime.

### §11.2 — Reasons

1. **SwiftData + CloudKit requires a custom E2EE schema.** CloudKit
   syncs SwiftData models via `NSPersistentCloudKitContainer`. The
   synced records are stored in the user's private CloudKit database,
   which Apple protects with at-rest encryption and end-to-end
   protection when the user has Advanced Data Protection enabled — but
   the **schema is not end-to-end encrypted at the field level**. A
   OneWeave "Sacred Echo" ciphertext plus its nonce, tag, and unlock
   date would be visible to anyone with access to the iCloud account
   metadata (Apple itself, legal compulsion, account compromise).
   Field-level E2EE requires a custom sync engine (e.g., encrypt
   inside the app, sync opaque blobs via CloudKit Records or a custom
   service). That is a multi-month build with its own threat model
   review — not shippable in v1.0.

2. **It conflicts with the onboarding "no server" promise.** The
   onboarding flow already tells users "No accounts. No cloud sync.
   No ads. No analytics." Adding iCloud sync, even as an opt-in,
   requires changing that copy to honestly describe the new state.
   This is also a *behavior change* for users who currently believe
   that their OneWeave data is physically incapable of leaving the
   device. That trust is the basis of §2 (Privacy-First, Zero-Trust)
   and is not negotiable.

3. **Deferred to v1.1 with an explicit user opt-in flow.** The plan for
   v1.1 is to add iCloud Drive (document-based) sync of the
   export-bundle as an opt-in feature, behind a settings toggle that
   requires a non-empty reflectionText (per §4) explaining why the
   user wants the sync. This is a *user-initiated, file-level*
   export-and-store model — not a CloudKit schema mirror. It honors
   §2 because the bundle is the export envelope that already exists
   for portability (`PortableExport.swift`).

### §11.3 — User-facing impact

Users in v1.0 will see, read, and acknowledge the strengthened
onboarding copy at line 15 of `OnboardingView.swift`:

> **"No accounts. No cloud sync by default and not available in this
> version. No ads. No analytics. No 'engagement' optimization. No
> streak-shaming. No notification spam. Your reflection is yours —
> and only yours."**

This is a deliberate strengthening of the existing "No cloud sync."
phrase. The new phrasing is precise about *what is not available*,
not just *what is not default*.

### §11.4 — Technical debt and v1.1 migration plan

Implementing iCloud Drive export-bundle sync in v1.1 requires:

- [ ] **CloudKit schema (none required)** — file-level iCloud Drive
      storage of the existing `PortableExport` envelope; no new
      CloudKit container or record types.
- [ ] **E2EE layer** — wrap the export bundle in a per-user symmetric
      key (Keychain-resident, same pattern as `SacredEchoCipher`) so
      the on-disk bundle is opaque even to Apple. Threat-model review
      needed before shipping.
- [ ] **Opt-in flow** — new `SettingsView` panel: "Sync encrypted
      bundle to iCloud Drive" toggle, gated by reflection-gate
      (`ReflectionGate.recordReflection` + non-empty `whyText`),
      with an `iCloud Drive Sync — Decision Reverb` log entry written
      to `DecisionLog`.
- [ ] **Migration path** — first-launch detection for users upgrading
      from v1.0; the v1.0 SwiftData store is unaffected (it stays
      local); only the *opt-in* sync starts once the user toggles it.
- [ ] **Reversibility** — the opt-in must be reversible; turning off
      sync must delete the iCloud Drive copy and stop future writes,
      leaving the local store untouched.
- [ ] **Audit trail** — every opt-in / opt-out writes to `DecisionLog`
      with timestamp + reflection hash (not the reflection itself).
- [ ] **No background sync** — sync is foreground-only, on user
      request, to honor §3 (Calm Intelligence) and avoid silent
      background activity.

### §11.5 — Mac/UI follow-up notes

The Mac-side team owns:

- T190b — link this decision from the top-level `constitution.md`
  (already in v2.0 §2; v3.0 will add §11 as a sibling).
- Any Settings UI work for v1.1 is out of scope for v1.0.
- `PrivacyInfo.xcprivacy` already declares `NSPrivacyTracking = false`
  and an empty `NSPrivacyCollectedDataTypes` array; **no changes
  needed for v1.0**.

### §11.6 — Ratification

This amendment is **DRAFT**. To ratify v3.0:

1. User reviews this file and `constitution.md` together.
2. User explicitly approves the v2.0 → v3.0 amendment.
3. On approval, merge this file's §11 into `constitution.md`, bump
   the version header to v3.0, and update the Constitutional
   Amendments section at the bottom.

Until ratified, v2.0 remains in force. The behavior described here
(no iCloud sync in v1.0) is already in force under v2.0 §2 and §3;
this amendment only makes the decision explicit and adds the v1.1
deferral plan as constitutional text.

---

*Drafted 2026-06-28 by the OneWeave Linux build agent under spec
003-production-readiness / T190. Cycle 39 honest-gap closure.*