# OneWeave Threat Model
**Cycle 32 (2026-06-28)** — Linux-side deliverable for spec 003-production-readiness T104.

## Scope

This document enumerates the threats OneWeave must defend against, the assets being protected, and the mitigations either in place or scheduled. The model covers the iOS app as distributed via the App Store and the Linux dev harness used for Swift-data validation.

## Assets (in priority order)

| Asset | Sensitivity | Storage |
|---|---|---|
| **Sacred Echo plaintext** (reflections) | Highest | AES-256-GCM ciphertext in SwiftData, key in Keychain |
| **Life Graph entities/relationships** (incl. Private `isPrivate=true`) | High | SwiftData on-device + App Group encrypted envelope |
| **ReflectionGate gate entries** | High | SwiftData `ReflectionGateDecision` rows |
| **Calendar / Contacts / Health data** (when leash open) | High | OS-mediated; never copied to our sandbox except via Apple APIs |
| **FamilyPod heir/handoff declarations** | Medium | SwiftData (data subject to inheritance) |
| **Essence / mastery tier / streak metadata** | Low | SwiftData; no PII |
| **App Group snapshot (widget)** | Low | Encrypted envelope, `isExcludedFromBackup` |

## Threat actors

1. **Curious spouse / family member** with physical device access (most likely). Defended by Face ID + on-device encryption + private-mode entity flag.
2. **Lost / stolen device.** Defended by device passcode + on-device encryption + App Group excluded from iCloud backup (T106).
3. **Apple** (legal compulsion to decrypt iCloud backups). Defended by excluding our container from iCloud backup (T106) + no iCloud sync of Sacred Echoes.
4. **Compromised App Store distribution** (Xcode ghost attack). Defended by reproducible builds + post-install signature verification (planned).
5. **Jailbroken device with privileged process.** Defended by debug-log redaction (T145), sensitive operation gating (T144 jailbreak detection), and not relying on secure enclave for the threat model — jailbreak detection is defense-in-depth only.
6. **Network adversary.** Out of scope: OneWeave makes **zero network calls** by default. Any future sync (e.g. optional iCloud backup of export) must go through Data Leash explicit opt-in.
7. **Adversary who reads backup of the device via iTunes/Finder on a trusted Mac.** Defended by `isExcludedFromBackup` + encrypted envelope format.

## Trust boundaries

- **App sandbox ↔ OS APIs** (HealthKit, EventKit, Contacts). We trust Apple to mediate, but we redact at our boundary (only the fields we asked for).
- **App sandbox ↔ App Group container** (widget snapshot). Same app signature; encrypted envelope.
- **App sandbox ↔ UserDefaults / Keychain** (App Group snapshot, vault seed). Same app signature; encrypted vault seed; Keychain-protected.
- **User ↔ UI**. We trust the user; we **do not** trust attacker-mediated UI (jailbreak → fake button). Defended by T144 jailbreak detection (warn, don't block).

## Mitigations (current vs. planned)

### ✅ Shipped
- **AES-256-GCM** for Sacred Echo ciphertext + envelope (`SacredEcho.swift`, `AppLifecycleCoordinator.swift`).
- **HKDF-derived per-echo keys** from a vault seed (`SacredEchoCipher.perEchoKey`).
- **ReflectionGate** with 5 rules (`ReflectionGate.swift`) — enforces single-source-of-truth, no surprise reflection events.
- **Data Leash** with 9 categories (`DataLeashSettings.swift`) — user opt-in per integration.
- **`isExcludedFromBackup`** on App Group container (`AppLifecyclePaths.markContainerExcludedFromBackup`, T106).
- **No network calls** — grep-verified zero `URLSession.shared`, `https://`, or fetch APIs in production code.
- **On-device only** PII processing; no analytics; no crash reporting SDK.
- **Account-deletion** (5.1.1(v)) — `clearAllData` deletes all 11 model types + Sacred Echo ciphertext.
- **Reflection plaintext redaction** in essence ledger export (T107).

### 🚧 Scheduled
- **T142** — Screenshot shield on sensitive views (Mac-only, requires `UITextField.isSecureTextEntry` style masking for SwiftUI views).
- **T143** — App Switcher snapshot blur (Mac-only, requires scene-based snapshot override).
- **T144** — Jailbreak detection (defense-in-depth; warn user, do not block — jailbroken users may have legitimate privacy reasons).
- **T145** — Debug log redaction (`#if DEBUG` builds only; production logs are stripped by Swift compiler).
- **T124/T132** — Privacy manifest `NSPrivacyAccessedAPITypes` entries: UserDefaults (CA92.1), DiskSpace (CA93.4), SystemBootTime (CA52.1), FileTimestamp (C617.1).

### ❌ Out of scope
- **Differential privacy** for any future aggregated insights (no aggregation currently exists).
- **Secure multi-party computation** for FamilyPod handoff (current model is "heir can read plaintext after death-certificate trigger"; no live sharing).
- **Encrypted backups** — iCloud backups are opted out; users wanting backup must export JSON manually and store it themselves.

## Risks the model accepts

1. **User passes the device unlocked to a trusted person.** We cannot defend against the user voluntarily handing over an unlocked device. Sacred Echoes unlock on a separate time trigger, not on authentication, so casual use does not reveal them.
2. **Compromised iOS.** If the OS is compromised, the model collapses. We rely on Apple's threat model.
3. **Quantum cryptanalysis.** AES-256-GCM is currently considered quantum-resistant at the key length used. HKDF chains are also post-quantum safe at 256-bit.
4. **Family heir who knows the vault seed.** The seed is device-resident, so this requires device access — same threat as #1.

## Validation

The threat model is exercised by:
- `validate_reflection_gate.py` — verifies no unauthorized reflection events.
- `validate_sacred_echo_crypto.py` — verifies AES-GCM round-trip + tamper detection.
- `validate_app_state_machine.py` — verifies no state transitions can leak data.
- `validate_p2p_flow.py` — verifies P2P share flow respects cooldown and refusal paths.
- **Static audit** — `grep -rE "URLSession|https?://" Sources/OneWeave/` should return only the deliberately-allowed whitelist (currently: 0 hits).

## Change log

| Cycle | Change |
|---|---|
| 32 (2026-06-28) | Initial threat model created (T104). Documented 7 threat actors, 11 mitigation categories, 4 accepted risks. |
