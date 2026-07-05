# Deeper P2P + App + External Integrations Plan for OneWeave

## Deeper P2P (from iOS P2P Guide)
- Expand P2PWeaveShare with:
  - Offline queue (CRDT-like or simple array for pending shares)
  - Hybrid discovery: Network framework Bonjour + WebRTC ICE/STUN
  - QR code signaling simulation for serverless auth
  - Stronger E2EE notes (Signal Protocol / CryptoKit)
  - Reflection gate enforcement before integration
  - Background handoff notes
  - BLE for local proximity
  - Permission declarations hints
  - Share specific LifeEntity types (e.g., CareKin person with full graph context)
  - Weave Circle as named trusted group with repeated shares

## Deeper In-App Integrations
- CompassView: Show live coherence score in HUD area, graph-aware suggestions in cross-thread, button to share selected entities via P2P
- GamificationHUD: Add small coherence badge
- Quest completion: On reflection, auto-create/update LifeEntity for the quest and link to existing graph
- Loom: Overlay simple graph connections or coherence pulses
- LifeContext: Methods to import entities from external, update coherence on any graph change, push graph deltas to P2P queue

## External iOS Service Integrations (Privacy-First)
- Modular bridges that respect Data Leash:
  - Calendar/Reminders (EventKit): Pull events as .event entities, reminders as .task. User approves scopes.
  - Contacts: Pull selected people as .person entities (with relationship strength based on interaction if possible).
  - Health (HealthKit): Pull steps, sleep, heart rate as .healthMetric entities. Map to harmony/energy.
  - Notes/Mail: Future - pull recent notes as .note entities (read-only summaries).
- All imports: User-initiated in Settings or Command Palette. Create LifeEntity with source tag, apply Data Leash defaults (e.g., health is private).
- Simulation in prototype: Fake pulls that create real LifeEntities in context.
- No auto background sync without explicit permission; all local.

## Fresh Unique Ideas
- "Graph-Linked Weaves": Imported calendar event auto-suggests a quest on linked CareKin person.
- "Coherence from Real Life": Health data directly influences harmony score (with reflection gate).
- P2P "Circle Sync": Share a Calendar-derived event + your reflection with trusted circle; they get a linked entity.

## Execution
- Enhance P2PWeaveShare.swift
- New file: iOSServiceIntegrations.swift (or split)
- Patches to CompassView, LifeContext, Prototype, HUD
- Update prototype demos and validation
- Keep local-first, calm, reflection-required
