# OneWeave Patch Suggestions & Fixes for Production (Security, Privacy, Quality, Completeness)
**Based on 2026-06-26 Audit**  
Apply these to reach "full production" baseline: encryption, consent, no leaks, working code.

Prioritize: 1) Make it compile/run. 2) Real export + basic encryption. 3) Consent UI. 4) Remove leaks (CDNs, plaintext).

## 1. Critical Bug Fixes (Apply Immediately - Code Won't Build/Run)
These fix compile errors and crashes identified.

### Patch 1: Fix StewardshipThread inheritance (Thread.swift protocol)
**File**: Sources/OneWeave/StewardshipThread.swift

```diff
- final class StewardshipThread: Thread {
+ final class StewardshipThread: ThreadProtocol {
```

Also add import if needed (Foundation/SwiftData already there).

### Patch 2: Fix DataSeeder.swift call signatures
**File**: Sources/OneWeave/DataSeeder.swift

```diff
-             st.addSubscription("Spotify", monthlyCost: 10.99, service: service, context: context)
-             st.detectLeak(serviceName: "unused-app", estimatedMonthlySavings: 9.99, service: service, context: context)
+             st.addSubscription("Spotify", cost: 10.99, service: service, context: context)
+             st.detectLeak(serviceName: "unused-app", reason: "unused or trial", savingsAmount: 9.99, service: service, context: context)
```

Update other calls in prototype/demo if they use old labels.

### Patch 3: Fix CompassView missing property reference
**File**: Sources/OneWeave/CompassView.swift (crossThreadSuggestions)

```diff
-         if let st = try? modelContext.fetch(FetchDescriptor<StewardshipThread>()).first, !st.savingsSuggestions.isEmpty {
-             s.append(st.savingsSuggestions.first!)
+         if let st = try? modelContext.fetch(FetchDescriptor<StewardshipThread>()).first, !st.recentInsights.isEmpty {
+             s.append(st.recentInsights.first!)
```

(Alternative: add `var savingsSuggestions: [String] = []` to StewardshipThread and populate it in detectLeak/recentInsights sync.)

### Patch 4: Fix AppStateMachine transition signature + calls
**File**: Sources/OneWeave/AppStateMachine.swift

Make param optional (since unused in body + inconsistent calls):

```diff
-    func transition(on event: TimelineEvent, context: LifeContext) {
+    func transition(on event: TimelineEvent, context: LifeContext? = nil) {
```

**File**: Sources/OneWeave/TimelineService.swift (line ~38)

```diff
-         stateMachine.transition(on: event)
+         stateMachine.transition(on: event, context: nil)
```

(Or better long-term: remove context param entirely; logic lives in LifeContext.)

Update any other direct calls if strict.

### Patch 5: Make export real (at least basic JSON)
**File**: Sources/OneWeave/SettingsView.swift

Replace stub `exportAllData()` with proper serialization. (Requires @Query for events/threads too.)

Add to struct:
```swift
@Query private var allEvents: [TimelineEvent]
@Query private var selfThreads: [BasicSelfThread]
// etc for others
```

Then:
```diff
-    private func exportAllData() {
-        var export = "OneWeave Full Export\n\n"
-        if let ctx = contexts.first {
-            export += "Energy: \(ctx.energyProfile.rawValue)\nSeason: \(ctx.values["season"] ?? "—")\n\n"
-        }
-        export += "See History and Threads for full events.\nExported at \(Date())"
-        exportData = export
-        showExport = true
-        ...
+    private func exportAllData() {
+        var exportObj: [String: Any] = [
+            "exportedAt": Date().ISO8601Format(),
+            "version": "oneweave-1",
+            "energy": contexts.first?.energyProfile.rawValue ?? "normal",
+            "eventsCount": allEvents.count
+        ]
+        // Full: encode events + threads
+        if let data = try? JSONEncoder().encode(allEvents) {
+            exportObj["eventsSample"] = String(data: data.prefix(500), encoding: .utf8) ?? ""
+        }
+        exportData = (try? JSONSerialization.data(withJSONObject: exportObj, options: .prettyPrinted)).flatMap { String(data: $0, encoding: .utf8) } ?? "Export failed"
+        showExport = true
+        ...
```

Better: Add full export func that builds complete dict or uses Codable models.

## 2. Encryption Patches (Core Production Requirement)
White paper demands user-controlled keys + encrypted exports.

### Swift (CryptoKit - add to project)
Add `import CryptoKit` to SettingsView or new ExportService.

Example basic encrypted export func (passphrase-based):

```swift
import CryptoKit

private func exportEncrypted(with passphrase: String) -> Data? {
    guard let ctx = contexts.first else { return nil }
    // Collect full data (simplified)
    let dataToEncrypt = try? JSONEncoder().encode(["energy": ctx.energyProfile.rawValue, "events": /*...*/ ])
    guard let plaintext = dataToEncrypt else { return nil }
    
    let key = SymmetricKey(data: SHA256.hash(data: Data(passphrase.utf8)))
    let sealed = try? AES.GCM.seal(plaintext, using: key)
    return sealed?.combined
}

// Usage: prompt user for passphrase via SecureField, then write .encrypted file or base64.
```

Store salt/iterations for production PBKDF2 (use CryptoKit or CommonCrypto).

For at-rest: In Xcode project settings or code, use URL with .completeFileProtection.

### PWA (Web Crypto - harden existing)
**File**: deliverables/oneweave-pwa.html (and copy to oneweave-web)

Improve exportEncrypted():

- Prompt for passphrase.
- Derive key with PBKDF2 (not raw generateKey each time).
- Do NOT bundle the key in export JSON. User must remember passphrase.
- Always require secure context or warn strongly.

Sketch:
```js
async function exportEncrypted() {
  const passphrase = prompt("Enter passphrase to encrypt export (remember it!):");
  if (!passphrase) return;
  const enc = new TextEncoder();
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const keyMaterial = await crypto.subtle.importKey("raw", enc.encode(passphrase), "PBKDF2", false, ["deriveKey"]);
  const key = await crypto.subtle.deriveKey(
    { name: "PBKDF2", salt, iterations: 100000, hash: "SHA-256" },
    keyMaterial,
    { name: "AES-GCM", length: 256 }, true, ["encrypt"]
  );
  // ... encrypt with random iv ...
  const payload = { encrypted: ..., iv: ..., salt: Array.from(salt), meta: ... };  // NO key
  // download
  showToast("Encrypted. Use SAME passphrase to decrypt later.", "Meaning");
}
```

Add decrypt function too.

Fallback warning: "LocalStorage is NOT encrypted. Use https + strong device passcode."

## 3. Consent Flow Improvements
### Onboarding (OnboardingView.swift)
Add final consent page:

```swift
// In pages or after loop
Toggle("I understand all data stays local on this device. I control export and deletion. No data leaves without my explicit action.", isOn: $consented)
Button("Start Weaving") { if consented { ... } }
```

Persist consent flag (e.g. in LifeContext or UserDefaults).

### Settings Additions
Add section:
```swift
Toggle("Enable Cross-Thread Ripples (affects energy/insights)", isOn: $smartRipples)
Toggle("Store Full Event Payloads (recommended for full history)", isOn: $fullPayloads)
Button("Export Encrypted Backup (enter passphrase)") { ... }
Text("Data volume: \(allEvents.count) events. Last cleared: ...")
```

For clear: detailed message "This will delete X events across 4 threads permanently."

### PWA
Enhance clearAllData() and add privacy modal with explicit acks.

## 4. No-Leaks / Privacy Hardening Patches
- **Remove externals in PWA**:
  Replace CDNs with:
  - Tailwind: self-host or use plain CSS / inline critical.
  - Icons: Use SVG inline or system (for native) / emoji / heroicons local.
  - Fonts: system-ui + serif fallback only.

  Add meta CSP if served.

- **Redaction helper** (new or in export):
  ```swift
  func redactedPayload(_ p: [String:String]) -> [String:String] {
    var r = p
    // simple: mask known sensitve
    for (k,v) in r { if v.lowercased().contains("family") || ... { r[k] = "[redacted]" } }
    return r
  }
  ```
  Call before export or in insights.

- **PWA localStorage warning**: On load, if !window.isSecureContext { show banner "For best privacy, use https or localhost. Data is plaintext." }

- **Swift**: Add to TimelineEvent or export: option to exclude raw payloads.

- Remove leftover prints or guard with #if DEBUG.

- In web: avoid innerHTML where possible; use textContent or safe createElement.

## 5. Completeness / Polish Patches
- **Full JSON export + import**:
  Make models Codable (add to @Model classes or separate DTOs).
  Implement bidirectional.

- **Add missing to Stewardship** (if keeping separate suggestions):
  ```swift
  var savingsSuggestions: [String] = []
  // in detectLeak etc: savingsSuggestions.append(...)
  ```

- **PWA**: Extract JS to modules if possible; add manifest.json for installable PWA; basic service worker for offline.

- **Update docs**: Edit IMPLEMENTED_FEATURES.md / README to reflect "prototype with bugs; see AUDIT for status". Remove overstated "production-ready".

- **Tests**: Add XCTest for TimelineService.emit, state transitions, leak detection.

- **Data Protection**: In app delegate or info: NSFileProtectionComplete.

- Duplicate PWA: Consider symlink or consolidate to one canonical.

## 6. How to Apply (Examples)
Use `patch` tool (as done in audit) or manual edit:

Example terminal/patch usage for one:
```bash
# After review
```

For larger, use search/replace carefully or full write.

**Post-apply verification**:
- Rebuild (Xcode for Swift).
- Test export roundtrip.
- Check no external requests in PWA (browser devtools).
- Run grep for "savingsSuggestions|monthlyCost|Thread {" — should be clean.
- Manual: seed data, emit ripples, export encrypted, clear with confirm, inspect local storage minimal.

## 7. Additional Production Suggestions (Beyond Patches)
- **Crypto full**: Use libsodium or platform for E2E if sync added later (CloudKit private with encryption).
- **Consent formal**: Implement "purpose" selection on capture (Self vs CareKin etc).
- **Monitoring**: Local-only analytics (event counts only).
- **Compliance**: Add settings "Download my data" (full), "Delete account" (clear + confirm).
- **Web hardening**: Migrate sensitive state to encrypted IndexedDB or WASM crypto.
- **Release checklist**: Privacy policy, App Store privacy nutrition labels (data not collected/sold), accessibility audit, age rating.

Apply the bug fixes + encryption + consent first. Re-audit after.

This + AUDIT_REPORT.md should unblock production path.
```

## Evidence of Application (Critical Fixes Applied via Tools)
I will now apply the highest priority patches using the available `patch` tool for real changes to the codebase. This makes the deliverable "working" post-audit.