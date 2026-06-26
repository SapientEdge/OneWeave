# OneWeave User Journeys (MVP Examples)

These demonstrate the spec's "one interconnected journey" principle. Actions in one thread immediately produce visible ripples in Life Context, Timeline, Compass insight, and other threads. All local-first.

## Journey 1: New Growth Goal in a Busy Season (Self → Care & Kin + Stewardship ripple)
**Trigger (Self thread)**: User captures "Start half-marathon training" via Quick Capture or Self thread.

**Expected ripples (event-driven via TimelineService → LifeContext → Compass)**:
- Energy drops to "low" (new goal affectsEnergy).
- LifeContext values update: season → "High Care Load", focus = "half-marathon training".
- Insight becomes: "Recent events show low energy in a High Care Load season. Simplify 2 items in Care & Kin; focus on half-marathon training only."
- Timeline shows Self:goal_added + linked ripples.
- CareKin thread surfaces suggestion: "Schedule a 15-min walk with family instead of another screen session."
- Stewardship may flag resource check (training gear/time).
- Meaning thread can later capture legacy impact ("Started training for health legacy").

**Real-world bridge**: User is nudged toward analog time instead of more digital planning.

## Journey 2: Subscription Leak Discovered (Stewardship → Self + Meaning)
**Trigger (Stewardship)**: Detect leak "unused-app".

**Ripples**:
- TimelineEvent: Stewardship:subscription_leak.
- LifeContext: season → "High Stewardship Load", priorities include stewardship.
- Insight: "Stewardship activity detected. Resources may be freed. Redirect any time/money saved toward a Self goal or Meaning legacy experience."
- Self thread gets note on possible resource impact.
- Meaning thread offers: "Freed resources from leak → legacy experience?"
- Compass rings update; recent events list shows the leak with linked threads.

**Real-world bridge**: "Use one freed evening for an analog hobby or legacy project instead of digital consumption."

## Journey 3: Low Energy + High Care Load (CareKin dominant → Self adjustment)
**Trigger**: Multiple CareKin tasks added during busy period.

**Ripples**:
- Energy → low.
- Insight recommends simplifying CareKin items to protect Self momentum.
- Self thread processEvent reacts: "Care load detected — protect energy for habits."
- Quick capture or Self add will now route suggestions accordingly.
- User sees unified view instead of siloed apps.

All journeys are local. No data leaves the device. Insights use on-device logic (InsightGenerator rules; later Foundation Models).

See spec.md for acceptance criteria: action in one thread surfaces meaningful ripples immediately in Compass.
