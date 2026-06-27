# Agent Squad — OneWeave High-ROI Cycle Prompts

These prompts are designed for parallel dispatch to Grok, Kimi, Claude Code, Codex, and Nemotron (via Hermes auxiliary routing). **Prepend the no-training prefix from NO_TRAINING_PROMPT.md** to every CLI invocation. Keep prompts short + file-referencing (per multi-cli-coding-orchestration skill).

## Cycle 14 — Resonance Oracle wiring + Body-Thread + Contradiction Weaver + Cron

### 1. Grok (supergrok — concrete code review + low-level fixes)
```
You are a senior Swift/SwiftData engineer reviewing the OneWeave Life OS project.

Project root: /root/hermes-workspace/projects/oneweave
Key files to review:
- Sources/OneWeave/ResonanceOracle.swift (new, novel creative feature)
- Sources/OneWeave/P2PWeaveShare.swift (deepened earlier)
- Sources/OneWeave/iOSServiceIntegrations.swift
- Sources/OneWeave/LifeGraph.swift
- Sources/OneWeave/CompassView.swift (patches)
- Sources/OneWeave/OneWeavePrototype.swift

Tasks:
1) Find concrete compile/runtime risks in ResonanceOracle.swift (type mismatches, undefined refs to LifeEntity/LifeContext/TimelineEvent, missing @MainActor, force-unwraps).
2) List exact line ranges that need fixes.
3) Suggest minimal patches (output the swift code).
4) Flag any duplicate definitions across files.

Be direct, no fluff, no plan mode. Output: numbered list of (file:line) + ready-to-paste Swift fix.
```

### 2. Claude Code (opus — architecture + scoping honesty)
```
You are a principal Swift/iOS architect with max reasoning.

Project: /root/hermes-workspace/projects/oneweave (OneWeave Life OS)
Existing done: LifeGraph, P2P WeaveShare, DataLeash, Insight Engine, Coherence Score, Resonance Oracle (new), Command Palette stub, iOS service integrations (Calendar/Contacts/Health).

Tasks:
1) Wire ResonanceOracle into CompassView: where exactly (line ranges) and the minimal SwiftUI code.
2) Design Body-Thread Weaver: add HealthThread entity + low-coherence detection in iOSServiceIntegrations. Provide Swift struct + detection logic.
3) Add Contradiction Weaver to GraphInsightGenerator: detection rule + ritual prompt. Give Swift code.
4) Honest gap list for "production ready in Xcode": what Xcode targets / entitlements / secrets are still required.

Be direct, list priorities. No implementation of unrelated polish.
```

### 3. Kimi (k2.7 — UX/insight prioritization + parity)
```
You are a senior product + UX engineer.

Project: /root/hermes-workspace/projects/oneweave — privacy-first Life OS, weaving metaphor, calm gamification.

Tasks:
1) From the 5 creative novel features already ideated (Resonance Oracle, Contradiction Weaver, Body-Thread, Sacred Echo Vault, Invisible Mentor Network), which 1-2 should ship first for max human benefit + uniqueness? Justify briefly.
2) Suggest 3 small UX upgrades to make Resonance Oracle feel calm and embodied (not gamified/creepy).
3) Propose how the Command Palette should parse natural language to create entities/quests (intent list + sample regex/nlp mapping in plain text).

Output: short, scannable, actionable.
```

### 4. Codex (openai — implementation passes for Body-Thread + Contradiction + Oracle wiring)
```
You are an OpenAI coding agent. Implement the following Swift additions to /root/hermes-workspace/projects/oneweave:

A) Add LifeEntity(type: .health) specialization or bodyThread flag + HealthThread helper struct in LifeGraph.swift (or new file Sources/OneWeave/BodyThreadWeaver.swift).
B) Add detectLowCoherence(healthData:) -> Bool to iOSServiceIntegrations.swift and a gentle weavePausePrompt(...) that respects Data Leash.
C) Add detectContradictions(in context: LifeContext) -> [Insight] to GraphInsightGenerator.swift.
D) Patch CompassView.swift to expose a "🌟 Resonance Oracle" button that opens a sheet calling ResonanceOracle.simulate and commitWeave (reflection gate).

Be conservative: production-grade, no stubs, no TODOs left in shipped code. Output file paths + diffs.
```

### 5. Nemotron (ollama-cloud via Hermes auxiliary) — independent sanity pass
Use as a **review-only** pass on the produced patches. Hermes will route this through AUXILIARY_APPROVAL_MODEL if dispatched, or as a sub-agent task with role=leaf and a clear "review this swift diff, list 5 issues" prompt.

## Privacy / No-Training Guard (CRITICAL — prepend to every CLI prompt)
See .research/NO_TRAINING_PROMPT.md — paste this block verbatim above any "user content" in every invocation.
