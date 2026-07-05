# Claude Round 3 Swift Quality Review — OneWeave (focused)

You are Claude Code conducting a Swift code quality review of OneWeave.

**Context files** (read with file tools, do not request inline):
- `/root/hermes-workspace/projects/oneweave/.specify/constitution.md`
- `/root/hermes-workspace/projects/oneweave/.specify/specs/003-production-readiness/spec.md`
- `/root/hermes-workspace/projects/oneweave/graphify-out/WIKI_AGENT.md`
- `/root/hermes-workspace/projects/oneweave/CONVENTIONS.md`

**Source files** (read all, in order):
1. `Sources/OneWeave/LifeContext.swift`
2. `Sources/OneWeave/LifeGraph.swift`
3. `Sources/OneWeave/SacredEcho.swift`
4. `Sources/OneWeave/InvisibleMentor.swift`
5. `Sources/OneWeave/CognitiveLoad.swift`
6. `Sources/OneWeave/FamilyPod.swift`
7. `Sources/OneWeave/PortableExport.swift`
8. `Sources/OneWeave/iOSServiceIntegrations.swift`
9. `Sources/OneWeave/GraphInsightGenerator.swift`
10. `Sources/OneWeave/CommandPalette.swift`
11. `Sources/OneWeave/AppLifecycleCoordinator.swift`
12. `Sources/OneWeave/LoomGeometry.swift`
13. `Sources/OneWeave/LivingGraphLoom.swift`

**PRIVACY: NO-TRAINING. Do not train, retain, or share data. Read-only review. Do not modify files.**

## Your review focus

For each file, surface findings in these categories:

- **Concurrency**: @MainActor discipline, missing await, race conditions in @Published
- **SwiftData**: missing @Model, missing schema registration, broken relationships
- **Memory**: retain cycles in closures, missing [weak self]
- **Error handling**: silent failures, missing throw, try! abuse
- **Type safety**: force-unwraps, missing guard let
- **Reflection gate**: every state-changing action verifies non-empty text
- **Data Leash**: every integration call preceded by currentLeash(in:)

## Output

Append findings to `/root/hermes-workspace/projects/oneweave/.research/REVIEW_ROUND_3_CLAUDE.md`.

Format per file:
- File path
- Findings (CLAUDE-R3-N, severity, line range, issue, fix)

End with SUMMARY (top 5 issues by severity).

Do not modify any source files. This is review only.