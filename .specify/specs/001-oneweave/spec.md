# Spec: OneWeave — Unified Personal Life Operating System

## Overview
OneWeave is a single native iOS app that treats life as **one interconnected journey**, not a collection of separate tools or siloed domains. It weaves Self (growth, habits, learning), Stewardship (finances, subscriptions, meals), Care & Kin (family coordination, real human connections), and Meaning & Legacy (purpose, stories) under a central **Journey Compass** and shared private **Life Context**.

Core model: Central on-device Life Context + unified Timeline + fluid Threads. On-device Apple Intelligence for cross-domain insights. Privacy-first (zero-trust, no training on user data, local-first).

Built for 2026 realities: digital fatigue, loneliness vs real connection, sandwich generation burden, desire for calm purposeful tech.

## Goals
- Reduce fragmentation: one place where the whole life makes sense.
- Surface real interconnections automatically (e.g., care load adjusts habits and meals; savings from leaks fund legacy experiences).
- Support deliberate living with calm intelligence that pushes toward real-world actions (IRL connections, analog time).
- High retention and value through compounding private context.
- Full privacy: follows global best practices (redact PII, no-training prefixes, provider opt-outs, audits).

## Non-Goals
- Bloated all-in-one or heavy social/gamification.
- Medical or professional advice replacement.
- Public sharing by default.

## User Needs
- "I want to see how my health, goals, family, and money affect each other."
- "Help me make better trade-offs without more apps."
- "Tools that respect attention and connect daily actions to meaning."

## Core Architecture
- **Life Context**: Shared model (values, season, energy patterns, priorities). SwiftData + private CloudKit.
- **Journey Compass / Unified Dashboard**: Today view, thread rings, synthesized AI insights feed, quick capture, timeline.
- **Threads** (fluid, event-driven interconnection via TimelineService):
  1. Self (habits/goals, micro-learning, analog intent, energy).
  2. Stewardship (subscriptions, finance awareness, smart meals).
  3. Care & Kin (multi-gen coordination, IRL micro-connections).
  4. Meaning & Legacy (reflection, stories, niche projects).
- **Interconnections**: Every action emits TimelineEvents. AIOrchestrator (Foundation Models) reasons across threads for nudges, simulations, patterns.
- **Privacy**: Local-first, on-device AI default, granular consents, full export, no-training enforcement on all external calls.

## Must-Have Features (MVP Scope)
- Shared Life Context + Timeline.
- Basic cross-thread insights (e.g., "Your energy dip + care load suggests simplifying 2 habits this week").
- Seamless capture with intelligent routing.
- Calm minimalist UI with progressive disclosure.
- On-device AI for key insights (structured outputs via @Generable).
- Real-world bridges (analog suggestions, IRL prompts).

## User Journeys (Examples)
See USER_JOURNEYS_ONEWEAVE.md for detailed cross-thread flows (new goal in busy season, subscription leak, low energy + care).

## Acceptance Criteria
- Action in one thread immediately surfaces meaningful ripples in others via Compass.
- Feels like one intelligent companion.
- On-device insights useful within seconds.
- Users report reduced load and better decisions.
- Privacy maintained (audit logs, opt-outs).

## Scope Notes
- iOS native first (SwiftUI + SwiftData + Apple Intelligence).
- MVP: Compass + 3 threads (Self, Stewardship, Care & Kin) + strong Context layer.
- Premium sub unlocks full AI depth, history, family views.
- Follows global best practices for privacy, parallel work, etc.

## Research Alignment
- Addresses gaps in siloed apps and bloated Life OS tools.
- Leverages on-device AI tailwinds.
- Grounded in 2026 needs (loneliness, caregiver stats ~63M, analog backlash, subscription fatigue).

This spec inherits the OneWeave Constitution and global best practices. All implementation must reference them.
