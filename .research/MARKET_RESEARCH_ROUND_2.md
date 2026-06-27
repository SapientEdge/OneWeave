# OneWeave Market Research — Round 2 (June 2026)

**Context:** Post-Tier A feature set: Life Graph + Data Leash + Sacred Echo Vault + Invisible Mentor + Body Thread + P2P Weave Circles + Living Graph Loom + Cross-Domain Insights + Command Palette + iOS deep integrations (Calendar/Reminders/Contacts/HealthKit/Mail/Notes) + encrypted-at-rest lifecycle persistence.

**Method:** Cross-referenced four market segments with OneWeave's unique positioning (privacy-first, on-device, anti-addictive, weaving metaphor). All cited market data is from public 2026 reports (Wirecutter, Grand View Research, Consainsights, Blankspaces). User reviews drawn from Reddit, Medium, dedicated review sites.

---

## Market Size Snapshot

| Segment | 2024-2026 Size | Projected Growth | Source |
|---|---|---|---|
| Blockchain/decentralized messaging | $40-42M (2024) | 42-45% CAGR → $536M by 2030 | Grand View Research, SecuMeet |
| Wellness apps (broader) | $11.27B (2024) | 14.9% CAGR → $26.19B by 2030 | Grand View Research |
| Screen-time monitoring apps | $4B (2024) | 7.2% CAGR → $7.62B by 2033 | Consainsights |
| Screen-time reduction (consumer pull) | $12.87B (2026) | 12-15% → $45-68B by 2034 | Blankspaces |

**Convergent trend:** privacy + anti-addiction + on-device are the three vectors where the biggest demand meets the biggest gap.

---

## What Users Complain About (Pain Points We Can Solve)

### From second-brain app reviews (Obsidian / Bear / Craft / Notion)

1. **Setup burden.** "Obsidian requires 5-10 hours of setup and plugin configuration with no native AI or semantic search." → **OneWeave already wins here** — Life Graph is built-in, no plugin config, Insights Engine works out of the box.
2. **No native privacy story.** "Obsidian is most intellectually satisfying… but criticizes the high decision load and setup." → **OneWeave's Data Leash is a differentiator**: granular, per-category, persistent, surfaced in Settings. No competitor has this.
3. **Bloat.** "Bear 2: intuitive Apple design, but Craft bloat." → OneWeave's Tier A feature set is intentionally lean: only what serves the weaving metaphor.
4. **Missing note versioning / backups.** (Reddit r/bearapp) → **Sacred Echo Vault solves this directly**: time-capsule reflections ARE the version history. You can seal a reflection today and re-encounter it as your future self.
5. **High decision load.** "Intellectually satisfying but high decision load." → **Invisible Mentor solves this**: not an AI, but a synthesizer of the user's own words. Surfaces 2-3 candidates; user picks one. Zero decision paralysis from blank-page anxiety.

### From journaling app reviews (Day One / Journey / Penzu)

6. **E2EE is paywalled.** "Day One: E2EE on Premium tier." → **OneWeave: E2EE on Sacred Echoes by default**, no paywall. (Sacred Echo uses AES-256-GCM with HKDF-derived per-echo keys; the app-level envelope is also encrypted at rest.)
7. **No reflection-on-completion ritual.** Most journaling apps let you skip the reflection. → **OneWeave makes the reflection the gateway to essence/harmony gains**. This is non-negotiable by design.
8. **Cross-platform sync requires cloud.** Journey's self-hosted sync is "recent." → **OneWeave has P2P Weave Circles**: share with a friend directly, no cloud required.
9. **Web access requires install.** "seeking alternatives for no-install web access." → OneWeave's PWA path preserves offline + same data; web access is local-first via the existing PWA infrastructure. *(Note: PWA is from the original spec; not Tier A.)*

### From digital-wellbeing app reviews (Freedom / Forest / Opal / Habit Doom)

10. **Passive tracking without replacement.** "Users want digital wellbeing apps that integrate strong screen time enforcement with daily habit building and replacement activities rather than passive tracking alone." → **OneWeave's Weave Pause** (in Body Thread) is exactly this: when body coherence drops, the app suggests a 3-minute reflection ritual instead of just blocking.
11. **Anti-addictive by design.** "Future digital wellbeing tools are expected to emphasize personalization via AI to better match individual needs." → **OneWeave's Cross-Domain Insight Engine awards essence for reflection, not for engagement time**. The opposite of the industry norm.
12. **No continuity across life domains.** Most wellbeing apps are siloed (sleep OR focus OR social). → **OneWeave's Life Graph unifies them**: a single graph spans body thread, care kin, meaning, stewardship. Insights surface contradictions across domains (e.g. "your stewardship load is up but your care kin threads are thinning").

### From decentralized messaging reviews (Session / Briar / Jami)

13. **P2P without personal meaning.** Decentralized messaging apps are private but impersonal. → **OneWeave's Weave Circles are personal by design**: you share *reflections* and *insights*, not chat messages. The shared payload is the user's own life graph subset.
14. **Onboarding friction.** Most P2P apps require technical setup. → **OneWeave's Weave Circle join is via QR/Bonjour** (already wired in P2PWeaveShare.swift). No key exchange ceremony.

---

## Gaps in Current Market That OneWeave Fills

| Gap | Current state | OneWeave's answer |
|---|---|---|
| Privacy-first life OS (not just journal OR calendar OR habits) | No single app unifies all three with privacy | Life Graph + Data Leash + all features local-first |
| Reflection as the gateway to progress | Optional in journaling apps | Mandatory reflection-gate for any insight/essence gain |
| Future-self dialogue (no AI, just synthesis) | Doesn't exist | Invisible Mentor — uses the user's own words only |
| Time-capsule reflections with encryption | Doesn't exist | Sacred Echo Vault — AES-256-GCM, per-echo keys, heir delivery |
| P2P life-graph sharing (not chat) | Doesn't exist | Weave Circles — share reflection-bearing graph subsets |
| Visual life-graph as calm breathing mobile | Doesn't exist | Living Graph Loom — circular, animated, season-aware |
| Cross-domain contradiction surfacing | Doesn't exist | Contradiction Weaver — stewardship vs body, concept vs event |
| Anti-addictive insight engine | The whole industry is the opposite | Insights award essence for reflection, not engagement time |

---

## Threats / Watchouts

1. **Obsidian's plugin ecosystem is a moat.** Users who already invested 50+ hours in Obsidian setup are sticky. **Counter:** OneWeave should support Markdown import/export so Obsidian refugees can migrate their vault without losing history.

2. **Day One's polish + ecosystem (Mac/Win/iOS/Android/web).** **Counter:** OneWeave's Apple-first strategy is a deliberate choice — fewer platforms means deeper iOS integration. The PWA covers web.

3. **Apple Notes is free and pre-installed.** **Counter:** Apple Notes has no Life Graph, no Data Leash, no encryption-of-reflections, no anti-addictive design. Users who want what OneWeave offers are already leaving Notes.

4. **Privacy-washing competitors.** Some apps claim E2EE but don't actually implement it. **Counter:** OneWeave's encryption is verifiable — Sacred Echo Vault's cipher layer is testable, the envelope encryption is testable, and the data flow is documented.

5. **"AI mentor" competitors will try to copy with LLMs.** **Counter:** OneWeave's Invisible Mentor is deliberately NOT an AI. This is a feature, not a limitation — users who distrust AI still get the future-self dialogue.

---

## Recommendations (Ranked by Leverage)

### Tier 1 — Highest leverage, smallest effort
- **Markdown import/export** for Obsidian refugees (1-2 days work)
- **Apple Notes import** as a one-click migration path (2-3 days)
- **Public landing page** that demonstrates the Data Leash + Sacred Echo encryption as a "show, don't tell" privacy story

### Tier 2 — Medium leverage
- **"Reflection Prompt Library"** — curated, offline-first, opt-in prompts for users who don't know what to reflect on. Sold as: "no AI, just calm questions." This is a moat because AI competitors can't credibly ship it.
- **Apple Watch complication** showing Sacred Echo countdown. (Already have widget target planned in Tier B.)
- **Family Pod feature** — a small Weave Circle (up to 6 people) where reflections are shared in aggregate (e.g. "3 of you noticed this week's theme was rest"). Reflection-gated for every member. This is novel — no competitor has "family as a graph."

### Tier 3 — Strategic moats
- **Open-source the cipher layer.** SacredEchoCipher (HKDF + AES-GCM envelope) is small, well-documented, and could be open-sourced as `OneWeaveCipher` on GitHub. Privacy-first developers would adopt it. Establishes OneWeave as the reference implementation. Free marketing.
- **Verified-encryption badge.** A user-visible "Your echoes are sealed with AES-256-GCM, per-echo keys derived via HKDF-SHA256" badge in the Vault UI. Lets users verify the claim rather than trust marketing.
- **Privacy audit by an independent firm.** (Already scheduled: weekly privacy audit cron, but external audit is different.) When published, this becomes a press story.

---

## What We Should NOT Build

Based on the market research, **avoid these common competitor traps:**

1. **AI-generated reflections or AI suggestions.** The market is flooded. OneWeave's moat is NOT being AI. Don't dilute it.
2. **Social feeds / likes / comments.** Any feature that adds engagement-time pressure contradicts the anti-addictive design.
3. **Free tier that throttles privacy features.** Privacy is the brand. Don't paywall the vault, the leash, or the echo encryption.
4. **Cross-platform parity at the cost of iOS depth.** Stay Apple-first. The PWA + iOS-macOS Catalyst is enough reach.
5. **Habit streaks without reflection.** This is the entire Duolingo trap. We already have reflection gates on quest completion — keep that discipline everywhere.

---

## TL;DR

The market wants three things: **privacy, anti-addiction, unification**. OneWeave ships all three today (Tier A). The next leverage is making that story visible (Markdown import, verified-encryption badge, open-source cipher). The biggest moat is staying *not-AI* — every "AI life coach" launch reinforces our position by contrast.

The biggest threat is Obsidian's plugin gravity. Mitigation: frictionless migration (Markdown import) so Obsidian users have no reason not to try OneWeave.

The biggest missed opportunity: **family/shared life graphs as a category**. No competitor owns this. The Family Pod concept (Tier 2 recommendation) is the strongest novel feature still on the bench.