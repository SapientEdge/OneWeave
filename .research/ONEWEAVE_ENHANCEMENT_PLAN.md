# OneWeave → Unified Life OS Enhancement Plan
**Directive**: Enhance, do not replace. Keep all finished gamification (essence, quests+reflection gates, harmony, seasons, Living Loom, widgets, PWA, no-stub production code). Use the 5 research documents to add depth, structure, AI, connectivity, and market positioning.

## Document Assignments (Multi-Agent)
- **Feature Matrix + Life Graph details** → Claude (Opus 4.8 max thinking): Formal entity model + SwiftData integration.
- **P2P Messaging Guide** → Grok / SuperGrok: Hybrid Network + WebRTC integration plan + code.
- **Unified Life OS Blueprint** → Kimi (k2.7 + thinking): High-level architecture, UX patterns (command palette, data leash), positioning.
- **Privacy-First Local AI Market + Technical** → Parallel Kimi/Grok: Tech choices (llama.cpp/LLM.swift vs Core ML, vector DB), market gaps, pricing.
- **life_os_research.json** (10 research dimensions) → Hermes supervisor synthesis + Agent Squad for consistency.

## Core Mapping (Current OneWeave is Strong Foundation)
- Threads (Self, Stewardship, CareKin, Meaning) + TimelineEvent → Life Graph entities + relationships.
- WeaveTapestryView / Loom → Visual representation of the Graph.
- LifeContext (essence, harmony, mastery, activeQuests, seasons) → Wellness metrics + gamified coherence layer.
- Quests + mandatory reflection → Typed memory capture + Reflective Friction.
- SnapshotStore → Proactive / ambient data for widgets + future agent.
- Existing privacy work → Zero-telemetry baseline + Data Leash extension.

## Prioritized Enhancement Roadmap (from Feature Matrix + Blueprint)
**Tier 1 (High Impact, Lower Complexity — do first)**
1. Unified Life Graph (Entity Architecture) — Critical
2. Privacy-First "Data Leash" Controls — Critical
3. Universal Command Palette — High
4. Smart AI Task Router (settings + local-first toggle) — Critical
5. Typed Memory Capture (Episodic/Semantic/Procedural) — Critical

**Tier 2**
6. Cross-Domain Insight Engine
7. Dynamic Contextual Dashboard (enhance Compass + HUD)
8. Relationship Decay Tracking (build on CareKin)

**Tier 3 (P2P + Advanced)**
9. P2P Messaging for private weave sharing (hybrid Network/WebRTC + Signal Protocol)
10. Passive Burnout Detection + Cognitive Load Balancer (use existing harmony/energy)
11. Agentic features (on-device tools over the Graph)

## Technical Architecture Additions (respecting current stack)
- Data: Extend SwiftData @Models. Add vector embeddings (512-dim) via Accelerate or Couchbase Lite Vector Search for semantic search/RAG.
- AI: Tiered router (default "Keep everything on device"). Local via future LLM.swift / llama.cpp or Apple Foundation Models. Cloud opt-in only.
- P2P: Network framework (local Bonjour) + WebRTC data channels (internet). E2EE with CryptoKit or full Signal. Minimal STUN (free), optional self-hosted TURN/Coturn. Offline queue + APNs wake.
- UX: Add swipe-down Command Palette. Extend existing floating actions to Omni-Action. @entity linking in notes/threads.
- Privacy: Granular per-category flags. Full local processing default. Privacy Nutrition Label "No Data Collected".
- Background: BGProcessingTask for nightly graph maintenance + insight generation.
- Widgets/App Intents: Extend current for proactive Life Graph insights.

## Execution Process (Multi-Agent + Squads)
1. Hermes loads agent-squad-orchestrator + creates specialists.
2. Parallel CLI runs (one doc/theme per CLI) produce:
   - Architecture/code for Life Graph (Claude)
   - P2P modules + integration (Grok)
   - Prioritized tasks + UX specs (Kimi)
3. Supervisor merges into .specify or .research/ plan, then direct edits or sub-delegation.
4. Verify against "finished product" rule: no stubs, maintains calm/anti-addictive (reflection gates, grace, IRL bias), local-first.
5. Update docs: tasks.md, LAUNCH_CHECKLIST, PrivacyPolicy, IMPLEMENTED_FEATURES.

## Immediate Next Steps (this session)
- [x] Read all 5 documents + inspect current code.
- [ ] Create local research copies in project.
- [ ] Dispatch CLIs with targeted prompts (using local .research/ files).
- [ ] Produce detailed Life Graph SwiftData models + integration diff.
- [ ] Produce P2P architecture + starter code.
- [ ] Synthesize prioritized task list.
- [ ] Update .specify/specs/002-gamification or create 003-lifeos-enhancement if needed.
- [ ] Implement first 1-2 high-value items (e.g. Life Graph base models + Data Leash settings screen).

## Guardrails (from all research + user history)
- Privacy by design: on-device default, explicit consent for anything leaving.
- Calm tech: No FOMO, required reflection for meaningful actions, grace mechanics.
- Production only: Every addition must feel finished.
- OneWeave identity preserved: Weaving life threads remains the core metaphor and visual language.
- Use all tools in parallel where possible (CLIs + Hermes delegation + terminal edits).

## Success Metrics
- Users can see their life as a coherent woven graph (not just gamified quests).
- Private P2P sharing of meaningful weaves without central servers.
- Local AI can eventually query the graph intelligently (future phase).
- Strong privacy positioning differentiates from Notion/Apple Intelligence/Rewind hybrids.
