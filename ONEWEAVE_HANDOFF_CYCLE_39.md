# ONEWEAVE_HANDOFF_CYCLE_39.md — 2026-06-28

**Status:** All cycle 39 deliverables shipped, all 5 cross-CLI reviews synthesized, ready for cycle 42 constitutional patches.

---

## What Shipped This Cycle

### T171-T178 — On-device semantic retrieval (Constitutional §2/§3/§4 compliant)

**Why we did this:** The Life Graph was a flat list of entities. Adding semantic search (NLEmbedding) gives every existing feature a multiplicative improvement — quick-capture routing, Invisible Mentor quote selection, future RAG. **Without** crossing the constitutional line into generation.

**Files:**
- `Sources/OneWeave/OnDeviceEmbedder.swift` (255 lines, NEW)
- `Sources/OneWeave/LifeGraph.swift` (+297/-24): `LifeEmbedding` struct, `cosineSimilarity`, `semanticSearch`, `missingEmbeddingFraction`
- `Sources/OneWeave/QuickCaptureInbox.swift` (+129): semantic tie-breaker at confidence < 0.6
- `Sources/OneWeave/InvisibleMentor.swift` (+95): semantic rerank with `semanticWeight = 0.3`
- `Sources/OneWeave/EmbeddingCoverageHint.swift` (NEW): T178b one-time banner
- `Sources/OneWeave/OneWeaveApp.swift`: added `VoidEntry.self` to modelContainer (closes Codex BLOCKER #18)

**Constitutional commitment preserved:**
- §2 Privacy: NLEmbedding is Apple-shipped, on-device, free; never sends data off-device
- §3 Calm: Mentor still quotes `seed.text` verbatim — only SELECTION uses semantic signal
- §4 Reflection-Gated: EmbeddingCoverageHint shows non-actionable banner, doesn't unlock anything
- §6 Genuine Help: fall-back to lexical works even without embeddings (50%+ threshold)

**Validation:**
- `audit/validators/validate_cycle39_embeddings.py`: 15/15 PASS
- Existing tests preserved: QuickCapture lexical 38/38, Invisible Mentor 12/12

### T190-T191 — iCloud / Private Cloud Compute deferral decision

**Why we did this:** Cycle 41's Claude audit asked whether the "no cloud sync" promise was binding or aspirational. We made it **binding** by amending the constitution.

**Files:**
- `CONSTITUTION_v3_DRAFT.md` (NEW, 145 lines): §11 explicit "v1.0 does NOT implement Private Cloud Compute sync." Lists three reasons, user impact copy, v1.1 migration plan (CloudKit schema, E2EE layer, opt-in flow, migration path).
- `Sources/OneWeave/OnboardingView.swift:15`: "No cloud sync by default and not available in this version."
- `Sources/OneWeave/PrivacyInfo.xcprivacy`: header comment declares `NSPrivacyAccessedAPICategoryiCloud` is intentionally NOT used.
- `FEATURE_CATALOG.md` §17: explicit iCloud deferral note.

**Constitutional commitment strengthened:** §11 makes the "no cloud sync" promise auditable. The decision is in `DRAFT` for user ratification.

### T228 — Void Thread sealed crypto

**Why we did this:** The most philosophically distinctive feature — single sentences sealed so the app CANNOT read them back unless the user re-types byte-for-byte. Closes the "your past self can hear you but your present self can't" loop that's unique to OneWeave.

**Files:**
- `Sources/OneWeave/VoidThread.swift` (456 lines, NEW):
  - `VoidEntry` `@Model`: only ciphertext, salt, nonce, tag (NO plaintext field)
  - `VoidCipher.seal(...)`: HKDF-SHA256 over `SHA256(plaintext)` + 16-byte random salt + per-entry info, then AES-256-GCM
  - `VoidCipher.unseal(...)`: temporal-gate check → derive key from re-typed text → AES-GCM.open → `String?`
  - `VoidUnlockCondition`: `.immediate`, `.dateInFuture(Date)`, `.afterNDays(Int)`, `.neverReveal`
  - Same `SecRandomCopyBytes` + `/dev/urandom` fallback as SacredEcho
  - `#if DEBUG`-gated `nowOverride` clock injection
- `audit/algorithm_oracle.py` (+290): 13 unit tests + HKDF/AES-GCM Python oracles. **73/73 tests pass** (was 60).

**Constitutional commitment preserved:**
- §2 Privacy: Fail-closed crypto, no test seed, no plaintext at rest
- §3 Calm: 280-char max sentence, never crashes on unread entries
- §4 Reflection-Gated: temporal gates require re-typing (a form of reflection)

**Validation:**
- `.research/validate_cycle39_void_thread.py`: 54/54 PASS (file existence + API surface + crypto properties + temporal gates + fail-closed)

---

## What Cycle 41 Cross-CLI Synthesis Found

5 CLIs reviewed in parallel:
- **Claude (constitutional)**: NEEDS_REMEDIATION — 7 violations, 5 spec drifts, 3 untested
- **Codex (correctness)**: 18 BLOCKERS, 12 HIGH, 4 MED, 2 LOW
- **Grok (architecture)**: TRUNCATED at 210 bytes (Linux limitation)
- **GLM 5.2 (creative)**: 5 spec critiques + reprioritization
- **Nemotron 3 Super (adversarial)**: refused (no tool access to file system)

**Top 3 constitutional HIGH (all Claude-only, NOT caught by any other lens):**
1. **Weave Pause body-depletion clause missing** (`CognitiveLoad.swift:235`) — HIGHEST LEVERAGE: 1 line patch
2. **MasteryKnot cap bypassed at 3 of 4 sites** (cycle 37 only fixed 1) — 3 lines
3. **ReflectionGate missing on season change** (`CommandPalette.swift:109`) — 10 lines

**Top verified Codex BLOCKERS:**
- ✅ `CompassView.swift:9` `\\.modelContext` double-escaped keypath (verified live)
- ✅ `AppLifecycleCoordinator.swift:262,281` missing `try` on `SacredEchoCipher.vaultSeed()` (verified live)
- ✅ `OneWeaveApp.swift` modelContainer missing VoidEntry (RESOLVED in this cycle)
- ❌ `LifeContext.swift:601` extension-before-class — FALSE POSITIVE (class closes at 599)

**Synthesis files:**
- `.cli/outputs/round_6_synthesis.md` (15.7 KB, full per-CLI breakdown, consensus list, unified fix list)
- `MULTI_AGENT_SYNTHESIS_CYCLE_41.md` (methodology + lessons learned)
- `audit/validators/validate_cycle41_consensus.py` (verifies all 5 outputs + synthesis + methodology)

---

## What Cycle 42 Will Fix

Per the cycle 41 synthesis, cycle 42 will close the 18 BLOCKERS + 12 HIGH before Mac handoff:

| Phase | Time | What |
|-------|------|------|
| 1 | 1h | Fix 18 Codex BLOCKERS (keypath escapes, try calls, type mismatches) |
| 2 | 1h | Apply 5 Claude HIGH constitutional patches (Weave Pause body, mastery cap ×3 sites, season reflection gate, P2P leash, test-seed DEBUG gate) |
| 3 | 1h | Replace 4 fatalErrors with throwing random + SwiftData wiring |
| 4 | 1h | Add 3 new validators (body-depletion, mastery-cap-all-sites, season-gate) |
| 5 | 30m | Fix 5 spec drifts (catalog lines, handoff claim, streak decay text) |
| 6 | 30m | Handoff doc |

**Target: 44/44 suites green + zero BLOCKERS for Mac handoff.**

---

## Suite Count Status

| Phase | Before | After | Delta |
|-------|--------|-------|-------|
| Algorithm oracle unit tests | 60 | **73** | +13 (TestVoidThread) |
| `.research/` validator suites | 39 | **40** | +1 (validate_cycle39_void_thread.py) |
| `audit/validators/` suites | 39 | **41** | +2 (validate_cycle39_embeddings.py, validate_cycle41_consensus.py) |
| **Cycle 42 target** | 40 | **44** | +4 (validate_weave_pause_body_depletion.py, validate_mastery_cap_all_sites.py, validate_season_change_reflection_gate.py, validate_cycle42_*.py) |

---

## Mac Handoff Notes

1. **SwiftData migration needed before TestFlight**: changing `embeddingData: Data?` → `embedding: LifeEmbedding?` is a type change. Lightweight migration won't handle this; **V5 stage with custom migrator required**. Fresh installs are fine.
2. **Constitution v3 ratification needed**: User must ratify CONSTITUTION_v3_DRAFT.md §11 (iCloud deferral) before it becomes binding.
3. **Cycle 41 BLOCKERs are pre-Mac-handoff ship-blockers**: 17 verified Codex BLOCKERS + 12 Claude HIGH — all Linux-fixable, must close before Xcode opens.
4. **EmbeddingCoverageHint UI test**: requires Xcode 15+ for `@AppStorage` SwiftUI testing.
5. **Void Thread UI**: needs a SwiftUI view with re-type prompt + biometric gate for `.neverReveal`. Mac-side work.

---

## Commits This Cycle

| SHA | Description |
|-----|-------------|
| `8b03c9e` | feat(embeddings): cycle 39 T171-T178 + Void Thread T228 + iCloud deferral T190/T191 |
| `0b4df81` | feat(cycle41): multi-agent cross-CLI synthesis report + consensus validator |
| `5648741` | docs(cli): 7-agent verification matrix — all CLIs operational 2026-06-28 |
| `e95aaf9` | docs(tasks): cycle 39-41 task list — honest gap closure + Apple Intelligence integration + multi-CLI synthesis |

---

## Lessons Learned (for the workflow blog)

1. **Multi-agent subagents timeout before finishing big tasks** — both cycle 39 subagents finished ~85% and asked for follow-up. **Solution**: split big tasks into smaller ones (T171-T178 could be 3 sub-streams: embedder, wiring, UI).
2. **Cross-CLI review catches what single-CLI misses** — Claude's constitutional lens found 3 HIGH issues that Codex (correctness-only) and GLM (creative-only) missed entirely.
3. **Constitutional weighting matters more than raw consensus** — only 10 items appeared in 2+ CLIs. Most issues are CLI-specific. Per-CLI weighting (Claude constitutional > Codex correctness > others) is the right model.
4. **Grok on Linux is broken for long outputs** — even with `grok-composer-2.5-fast` + `--prompt-file`, output capped at ~210 bytes. Need different model or larger context budget.
5. **Cloud Ollama models (Nemotron) have no tool access** — cannot do file:line review. Use local Ollama variant for adversarial work.
6. **Codex review is snapshot-based** — flagged T172/T228 as missing because subagent work was untracked. Either commit before review or note staleness in synthesis.
7. **The constitutional hierarchy is preserved**: Privacy > Reflection > Anti-addictive > Fail-closed > No-training. Cycle 41 found that the Weave Pause is missing the third conjunct in §5 — anti-addictive principle violation. This is the SINGLE highest-leverage patch.
