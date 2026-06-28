# OneWeave Cycle 30+ Test Design Expansion

## A. Top 15 New Python Validators

| # | File | What it validates | 1-line description | Expected tests | Key assertion |
|---|------|-------------------|--------------------|----------------|---------------|
| 1 | `validate_app_state_machine.py` | `AppStateMachine.transition` and `LifeContext.applyStateTransition` | Mirrors the full event-driven state table and settle-to-idle/reflecting rules. | 40 | Same event sequence always yields identical state chain; active states settle on neutral follow-up events. |
| 2 | `validate_essence_economy.py` | `LifeContext` essence awards, levels, amplifiers, decay | Models all income/spend paths including cross-thread bonuses, amplifier cooldown, gentle decay, and level thresholds. | 35 | `weaveEssence` is monotonic except for `spendEssenceForAmplifier` and decay; `levelProgress` stays in `[0,1]`. |
| 3 | `validate_reflection_gate_surface.py` | Every reflection gate in the codebase | Consolidates gates from `completeQuest`, `completeSeasonReflection`, `SacredEchoStore.seal/open/handDeliver/release`, `FamilyPod.exit`, `DecisionLog`, and Mentor insight. | 30 | Empty/whitespace input rejected everywhere; minimum-length gates (`20`/`30`) enforced with exact boundary cases. |
| 4 | `validate_life_graph_coherence.py` | `LifeGraph.buildCoherenceScore` | Mirrors graph coherence scoring over entities/relationships including private-flag filtering and contradiction hints. | 25 | Coherence score is in `[0,1]`; isolated entities lower score, densely linked same-domain entities raise it. |
| 5 | `validate_data_leash_privacy.py` | `DataLeashSettingsRecord` + integration gating | Verifies per-category toggles (mail, notes, reminders, health, calendar, contacts) block outbound PII independently. | 30 | When a category is disabled, no renderer produces text/URL/payload for that channel. |
| 6 | `validate_p2p_weave_share.py` | `P2PWeaveShare` conflict resolution & offline queue | Simulates peer sync: reflection-gated packets, last-write-wins conflicts, duplicate suppression, and queue cap. | 35 | Reflection-less packets are dropped; conflicting updates converge deterministically; queue never exceeds cap. |
| 7 | `validate_quest_lifecycle.py` | `WeaveQuest` accept/complete/reflect | Mirrors quest acceptance, active list management, completion with reflection length gate, and essence award. | 30 | `activeQuests` contains accepted-but-incomplete IDs only; double completion rejected; `completedQuestCount` increments once. |
| 8 | `validate_thread_ripples.py` | Cross-thread `linkedThreads` effects | Models how ripple events append threads, update `masteryTiers`, trigger resonance, and bound `harmonyScore`. | 30 | `masteryTiers` capped at 4; `harmonyScore` capped at 1.0; linked threads are added idempotently. |
| 9 | `validate_season_lifecycle.py` | `changeSeason` / `completeSeasonReflection` | Tests season transition tick, re-armed reflection gate, and one-time +10 burst. | 25 | `seasonReflectionCompleted` flips only on non-empty reflection; full burst awarded at most once per season. |
| 10 | `validate_widget_snapshot.py` | `OneWeaveSnapshot` + `pushSnapshotToWidgets` | Verifies snapshot payload privacy and consistency after essence events. | 20 | Snapshot always contains only non-sensitive badge fields; `lastUpdated` and `weaveEssence` are consistent with `LifeContext`. |
| 11 | `validate_migration_rollback.py` | Unsupported downgrade + idempotency | Tests `validateMigrationPath` for V3→V1, partial migration replay, and orphaned attribute handling. | 25 | Downgrades return non-nil error; re-running V1→V3 on already-V3 data is a no-op; no data loss on re-run. |
| 12 | `validate_time_travel_stability.py` | Calendar/streak/echo wall-clock behavior | Exercises streak day boundaries, grace windows, and echo unlock across time zones / DST. | 25 | `globalWeaveStreak` changes only at `startOfDay` boundaries; echo `state` depends only on absolute `unlockAt` vs `now`. |
| 13 | `validate_concurrency_actor_isolation.py` | `@MainActor` ordering assumptions | Simulates serialized event ingestion vs. parallel cache invalidation / snapshot pushes. | 20 | Final `LifeContext` state is identical under any serializable ordering of the same events; no lost essence updates. |
| 14 | `validate_onboarding_consent.py` | First-launch defaults and seed persistence | Checks default local-only Data Leash, vault seed persistence gate, and initial Family Pod owner grant. | 20 | Default leash blocks all external categories; `vaultSeed()` fail-closed path throws before any echo is sealed. |
| 15 | `validate_static_security_policy.py` | Source-level security lint | Regex-based checks on `Sources/OneWeave/*.swift` for crypto/policy anti-patterns. | 15 | No deterministic nonce reuse path; no plaintext reflection logged; keychain accessibility set to `AfterFirstUnlockThisDeviceOnly`. |

## B. Top 10 Property-Based Test Scenarios

1. **Streak/grace over arbitrary activity sequences** — Generate random daily event presence/absence and `energyProfile` values; invariant: streak never resets, `graceDaysUsed ≤ maxGraceDays`, and streak increments only on non-grace active days.  
2. **P2P conflict patterns** — Generate arbitrary interleavings of `P2PPacket` arrivals for the same entity from two peers; invariant: last-write-wins, no reflection text accepted without gate, digest never leaks ungranted fields.  
3. **QuickCapture over arbitrary strings** — Hypothesis strings up to 500 chars; invariant: output destination is always one of the five known cases, confidence ∈ `[0,1]`, title length ≤ 120.  
4. **V1 attribute migration over arbitrary JSON** — Generate arbitrary JSON blobs; invariant: `convertAttributesJSONToDict` never crashes, output is always `{String:String}`, malformed input → `{}`.  
5. **FamilyPod churn** — Random sequences of `add_member`, `remove_member`, `exit_pod`, `set_grant`; invariant: active count ≤ 7 (owner + 6), only owner changes grants, exit requires 20-char reflection.  
6. **SacredEcho lifecycle** — Random `unlockAt`, `openedAt`, and terminal-state raw values; invariant: terminal states are sticky, premature open throws `notYetUnlocked`, re-open throws `alreadyOpened`.  
7. **Essence economy event streams** — Random `TimelineEvent` sequences with varying `linkedThreads`; invariant: essence is never negative, level only increases, amplifier spend fails when balance insufficient.  
8. **AppStateMachine transitions** — Random event type strings and `affectsEnergy` flags; invariant: state is always one of the six enum cases, capture/weave/reflect events override energy-neutral events.  
9. **CognitiveLoad inputs** — Random dictionaries with numeric fields; invariant: score and all components ∈ `[0,1]`, WeavePause triggers only when `score ≥ 0.85` and trend is rising.  
10. **PortableExport bundles** — Random entity sets × leash × user intent; invariant: `local_only` produces zero bytes, `full_bundle` requires ≥30-char intent, reflection text absent under non-permitting leashes.

## C. Top 10 Cross-Module Integration Tests

1. **P2P share → reflection gate → essence award** — Receive a peer’s quest-completion packet; verify it is rejected without reflection, then accepted with reflection, and `LifeContext.weaveEssence` increases.  
2. **QuickCapture journal → AppStateMachine reflecting → insight cache invalidation** — Classify a journal input, confirm state becomes `.reflecting`, and that `GraphInsightGenerator` cache is invalidated.  
3. **SacredEcho handDeliver → FamilyPod heir validation → P2P redaction** — Designate a CareKin heir, hand-deliver an opened echo, and assert the generated P2P digest redacts plaintext and respects grants.  
4. **DailyBriefing high cognitive load → WeavePause gate** — Morning briefing with load ≥ 0.85/rising triggers WeavePause; verify empty commitment is blocked and non-empty commitment passes.  
5. **DecisionLog + MentorBridge + InvisibleMentor** — Record a decision, record its outcome, feed the reflection seed into the mentor, and assert the cited decision appears in top candidates.  
6. **Season change → reflection gate → LifeGraph + essence** — `changeSeason` arms the reflection gate, `completeSeasonReflection` inserts a graph concept entity and awards exactly +10 essence once.  
7. **Schema migration V1→V3 → LifeGraph coherence → widget snapshot** — Migrate legacy V1 JSON attributes, rebuild coherence, push snapshot, and assert `lifeCoherenceScore` and snapshot fields stay consistent.  
8. **DataLeash blocks Notes export** — With Notes category disabled, verify `NotesIntegrationLite` returns `None` and no `mailto`/`x-callback` URL contains reflection text.  
9. **RelationshipDecay severe → Quest → completion → decay reset** — A severe relationship prompt generates a quest; completing it with reflection updates the relationship’s `last_interaction_at` and clears the severe flag.  
10. **Essence-changing event → snapshot consistency** — Every event that changes essence (`quest_completed`, `echo`, `resonance`, `season_reflection`) triggers `pushSnapshotToWidgets`; snapshot values equal `LifeContext` values within one tick.

## D. Top 5 Crypto Regression Tests

1. **NIST AES-GCM SP 800-38D test vectors** — Validate PyCryptodome/CryptoKit-compatible AES-GCM seal/open against published NIST vectors for 12-byte nonce / 16-byte tag.  
2. **RFC 5869 HKDF-SHA256 test vectors** — Use the official IETF vectors to assert `HKDF<SHA256>.deriveKey` matches for `info`, `salt`, and output lengths of 32 and 64 bytes.  
3. **AES-GCM tampered ciphertext authentication failure** — Flip one bit in ciphertext, tag, or nonce; assert `open` throws and does not return partial plaintext.  
4. **Nonce reuse catastrophic failure** — Seal two plaintexts with identical nonce and key; assert decrypted plaintext of the second does not match (demonstrating GCM’s 96-bit nonce must be unique).  
5. **Per-echo key isolation** — Derive keys for two echo UUIDs using the same vault seed; assert keys differ, and opening echo A’s ciphertext with echo B’s key fails authentication.

## E. Test Infrastructure Improvements

1. **pytest fixtures** — Add `life_context()`, `model_context()`, `fixed_clock()`, `strict_leash()`, `open_leash()`, and `echo_factory()` fixtures in `.research/conftest.py` to remove boilerplate across the 19+ suites.  
2. **Shared helpers module** — Create `.research/testing_common.py` with `TimelineEvent` builders, `FakeLifeContext` defaults, HKDF/AES-GCM mirrors, and a deterministic UUID sequence for reproducible property tests.  
3. **Regression gating** — Add a top-level `.research/run_all_validators.py` that runs every `validate_*.py`, enforces a minimum total test count (e.g., 600+), and fails the CI step if any suite fails or if count drops.  
4. **Golden-file checks** — For property-based / randomized tests, persist a known-good corpus of example inputs and expected outputs under `.research/golden/` and compare on every run to catch nondeterminism.  
5. **Coverage reporting** — Run `coverage run` over the Python mirrors and fail if any mirror module falls below a pragmatic threshold (e.g., 85%), ensuring new Swift logic is accompanied by a mirror validator.

To resume this session: kimi -r 8d097a45-f36d-4cab-9814-0e9ab2bc660b
s step that runs the suite on every PR.
5. **Parametrized existing suites** — Convert the ad-hoc `check()` loops in `validate_cognitive_load.py`, `validate_daily_briefings.py`, and `validate_quick_capture.py` into `@pytest.mark.parametrize` tests so new edge cases are one-line additions.

**Recommended next step:** implement `validate_app_state_machine_divergence.py` and `validate_p2p_weave_share.py` first — these cover the highest-risk behavioral mismatches and privacy boundaries currently unvalidated.

To resume this session: kimi -r 71db42e2-01e3-4059-a935-30f40a10a848
