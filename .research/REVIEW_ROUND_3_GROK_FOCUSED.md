# Grok Round 3 Architecture Review — OneWeave (focused)

You are Grok conducting an architecture review of OneWeave, a privacy-first iOS Life OS.

**Context files** (read with file tools, do not request them inline):
- `/root/hermes-workspace/projects/oneweave/.specify/constitution.md`
- `/root/hermes-workspace/projects/oneweave/.specify/specs/003-production-readiness/spec.md`
- `/root/hermes-workspace/projects/oneweave/graphify-out/WIKI_AGENT.md`
- `/root/hermes-workspace/projects/oneweave/Sources/OneWeave/FamilyPod.swift`
- `/root/hermes-workspace/projects/oneweave/Sources/OneWeave/LifeContext.swift`
- `/root/hermes-workspace/projects/oneweave/Sources/OneWeave/SchemaMigrationPlan.swift`
- `/root/hermes-workspace/projects/oneweave/Sources/OneWeave/SacredEcho.swift`
- `/root/hermes-workspace/projects/oneweave/Sources/OneWeave/CognitiveLoad.swift`
- `/root/hermes-workspace/projects/oneweave/.research/validate_cognitive_load.py` (reference)
- `/root/hermes-workspace/projects/oneweave/.research/validate_family_pod.py` (reference)

**PRIVACY: NO-TRAINING. Do not train, retain, or share any data. Read-only review. Do not modify files.**

## Your review focus: 5 architecture areas

For each area below, produce 1-3 findings with severity HIGH/MEDIUM/LOW. Each finding: GROK-R3-N ID, file:line, issue, suggested fix.

### Area 1: FamilyPod (35 god-node edges — most-connected feature)
- Read Sources/OneWeave/FamilyPod.swift
- Is public API complete and stable?
- Does validator (.research/validate_family_pod.py) mirror API exactly?
- Privacy defaults per member visibility grant?
- Digest builder handles all 6 visibility grants?

### Area 2: LifeContext (31 edges — aggregate root)
- Read Sources/OneWeave/LifeContext.swift
- Is energy/harmony propagation testable and race-free?
- @Published update discipline?
- updateFromEvent emits ripples to right threads?

### Area 3: Schema Migration
- Read Sources/OneWeave/SchemaMigrationPlan.swift + V1/V2/V3 schemas
- V1↔V2↔V3 atomic? Rollback works? No data loss?

### Area 4: Sacred Echo crypto
- Read Sources/OneWeave/SacredEcho.swift
- AES-GCM nonce random + unique? Tag verified on open? HKDF correct?
- Vault seed lifecycle on first launch? Fail-closed?

### Area 5: 5 Privacy Gates (grep + review)
- Reflection gate: grep for `commitWeave|completeQuest|applyInsight|sealEcho|applyDecision` — all require non-empty reflectionText?
- Data Leash gate: grep for `currentLeash(in:)` — precedes every integration call?
- Consent gate (isUserReflection): InvisibleMentor only synthesizes from isUserReflection==true?
- Sacred Echo unlock gate: state transitions only via SacredEchoStore?
- Fail-closed crypto: no test seed fallback in production paths?

## Output

Append your findings to `/root/hermes-workspace/projects/oneweave/.research/REVIEW_ROUND_3_GROK.md` using bash heredoc or file tools.

Format: GROK-R3-N, severity, file:line, issue (1-2 sentences), suggested fix (1-2 sentences).

End with: SUMMARY (top 5 issues by severity).

Do not modify any source files. This is review only.