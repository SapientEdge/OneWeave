# Aider Conventions for OneWeave

## Commit Discipline

Every change is one feature = one commit. No bundling. Format:

```
<type>(<scope>): <short summary under 72 chars>

<body: 2-3 sentences explaining WHY, not WHAT>

Refs: .specify/specs/003-production-readiness/spec.md
```

### Types

| Type | When |
|---|---|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `refactor` | Code restructure without behavior change |
| `docs` | Spec/doc/comment changes |
| `test` | Test-only changes (Python mirrors, prototype harness) |
| `chore` | Build/tooling/meta |
| `perf` | Performance optimization |
| `build` | Xcode project / dependency changes |
| `ci` | GitHub Actions, signing, TestFlight |

### Scopes (must match)

- `life-graph` — LifeEntity, LifeRelationship, LifeContext
- `sacred-echo` — SacredEcho, SacredEchoCipher, MentorEchoBridge
- `invisible-mentor` — InvisibleMentor, DecisionMentorBridge
- `cognitive-load` — CognitiveLoad, WeavePauseGate
- `family-pod` — FamilyPod, FamilyPodPolicy, DigestBuilder
- `data-leash` — DataLeashSettings, IntegrationCategory
- `ios-integrations` — Calendar/Contacts/HealthKit/Reminders/Mail/Notes
- `loom` — LivingGraphLoom, LoomGeometry
- `briefings` — DailyBriefings (morning + evening)
- `capture` — QuickCaptureInbox
- `decisions` — DecisionLog
- `relationships` — RelationshipDecayTracker
- `export` — PortableExport
- `p2p` — P2PWeaveShare
- `widgets` — OneWeaveSnapshotStore, OneWeaveWidgetStubs
- `lifecycle` — AppLifecycleCoordinator, OnboardingView
- `schema` — SchemaMigrationPlan, OneWeaveSchemaV1/V2/V3
- `gamification` — WeaveQuest, QuestService, EssenceLedgerView
- `app` — OneWeaveApp, MainTabView
- `docs` — Markdown changes

## Code Style

### Match existing Swift style

- 2-space indent
- No trailing whitespace
- Lines under 120 chars
- `// MARK: -` for sections
- `///` doc comments only on public APIs
- `@MainActor` on any UI-touching class
- Async functions for I/O
- Enums for type-safe constants (no string literals)

### Privacy invariant checks (REQUIRED before commit)

Before committing any change, verify:

- [ ] No external API calls added (grep for `URLSession`, `URL(string:)`, etc.)
- [ ] No cloud sync code added (grep for `CKContainer`, `CloudKit`)
- [ ] No LLM/Core ML/network calls in core (grep for `CoreML`, `Network`, `URL`)
- [ ] Reflection gate maintained on state-changing actions (`commitWeave`, `completeQuest`, `applyInsight`, `sealEcho`, `applyDecision`, etc.)
- [ ] Data Leash check before every integration call (`currentLeash(in:)` precedes enumeration)
- [ ] Sacred Echo crypto remains fail-closed (no test seed fallback)
- [ ] No streak-shaming notifications
- [ ] No infinite feeds or attention-grabbing elements
- [ ] Color convention maintained (Self=.blue, Stewardship=.green, CareKin=.orange, Meaning=.purple)

### Test discipline
- Every new feature: Python mirror test in `.research/validate_<feature>.py`
- Every bug fix: regression test that reproduces the bug first
- Stress tests: 1k entity graphs, p2p packet storms, crypto roundtrip chaos
- Validate via `bash .research/validate_all.sh` before commit

## Sub-Agent Workflow (cycle 47+)

**Mandatory for any sub-agent expected to run >10 seconds.**

**Note:** The supervisor infra (`~/.hermes/scripts/cycle47/`) is **Hermes-global**, not OneWeave-specific. It works for any project — OneWeave, snapkeep, vst-alpha, etc. The OneWeave-local copy at `scripts/cycle47/` exists for historical reference but the canonical path is the global one.

Use `~/.hermes/scripts/cycle47/subagent_supervisor.py` (NOT direct `codex exec`) with `--marker-required --hung-threshold 600`. Every sub-agent prompt MUST include `marker.py start <task_id>` / `end <task_id>` calls referencing the global path.

Full policy: [`~/.hermes/scripts/cycle47/README.md`](~/.hermes/scripts/cycle47/README.md) (Hermes-global)
This project's cycle 47 handoff: [`specs/047-subagent-reliability/cycle47_handoff.md`](specs/047-subagent-reliability/cycle47_handoff.md)
Skill: `~/.hermes/skills/subagent-hung-vs-done-check/SKILL.md`

Trivial sub-agents (<10s, single file) may use `subagent_wrapper.py` directly. Never use raw `codex exec` without wrapping.

### Run before commit

```bash
# Validate
bash .research/validate_all.sh   # all 16 suites must pass

# Refresh graph
graphify update . --no-cluster

# Commit
aider --commit
```

## What Aider Will Refuse

Aider is configured to refuse changes that violate:

1. Privacy invariants (no cloud, no API, no training)
2. Anti-addictive design (no streak-shaming, no infinite feeds)
3. Reflection gate removal
4. Data Leash removal
5. Sacred Echo fail-closed crypto weakening
6. Architectural invariants (App Group ID, schema versioning, color convention)

If you need to violate these, you MUST update `.specify/constitution.md` first.

---

*This file is read by Aider on every session. Keep it current.*