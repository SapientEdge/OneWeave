"""
Tier A #2 validation mirror — replicates the Mail/Notes/Reminders gating
logic from iOSServiceIntegrations.swift in pure Python so we can verify
Data Leash respect + reflection-gate correctness on Linux.

We test:
  1. composeURL returns None when leash blocks; URL otherwise.
  2. composeURL returns None for empty recipient (even if leash allows).
  3. insightBody returns None for empty/whitespace reflection.
  4. insightBody returns None when leash blocks.
  5. insightBody returns a String when reflection present + leash allows.
  6. decisionBody requires reflection (returns None for empty).
  7. decisionBody denied when leash blocks.
  8. Notes reflectionPayload requires reflection + respects leash.
  9. Notes decisionPayload requires reflection + respects leash.
  10. Notes snapshotPayload requires summary + respects leash.
  11. Reminders createReminder requires reflection + respects leash.
"""

import urllib.parse
from dataclasses import dataclass, field
from typing import Dict, Optional


class IntegrationCategory:
    CALENDAR = "calendar"
    REMINDERS = "reminders"
    CONTACTS = "contacts"
    HEALTH = "health"
    NOTES = "notes"
    MAIL = "mail"
    ALL = [CALENDAR, REMINDERS, CONTACTS, HEALTH, NOTES, MAIL]


@dataclass
class DataLeashState:
    allowed_categories: Dict[str, bool]
    privacy_levels: Dict[str, bool]

    @classmethod
    def strict_default(cls):
        # Strict default blocks everything.
        return cls(
            allowed_categories={c: False for c in IntegrationCategory.ALL},
            privacy_levels={c: True for c in IntegrationCategory.ALL},
        )

    @classmethod
    def fully_open(cls):
        return cls(
            allowed_categories={c: True for c in IntegrationCategory.ALL},
            privacy_levels={c: False for c in IntegrationCategory.ALL},
        )

    def is_allowed(self, cat):
        return self.allowed_categories.get(cat, False)

    def is_private(self, cat):
        return self.privacy_levels.get(cat, False)


class MailIntegrationLite:
    @staticmethod
    def compose_url(to, subject, body, leash):
        if not leash.is_allowed(IntegrationCategory.MAIL):
            return None
        if not to.strip():
            return None
        params = {}
        if subject:
            params["subject"] = subject
        if body:
            params["body"] = body
        query = urllib.parse.urlencode(params)
        return f"mailto:{to}?{query}" if query else f"mailto:{to}"

    @staticmethod
    def insight_body(insight_title, reflection, leash):
        if not leash.is_allowed(IntegrationCategory.MAIL):
            return None
        if not reflection.strip():
            return None
        return (
            f"Subject: Weave note — {insight_title}\n\n"
            f"— Begin reflection —\n{reflection.strip()}\n— End reflection —\n\n"
            f"Sent from OneWeave. Your words, your privacy."
        )

    @staticmethod
    def decision_body(scenario_summary, reflection, leash):
        if not leash.is_allowed(IntegrationCategory.MAIL):
            return None
        if not reflection.strip():
            return None
        scenario_line = scenario_summary.strip() or "(scenario omitted)"
        return (
            "Subject: Weave decision\n\n"
            f"Scenario: {scenario_line}\n\n"
            f"My decision and why:\n{reflection.strip()}\n\n"
            "Sent from OneWeave. Local-first, your words only."
        )


class NotesIntegrationLite:
    @staticmethod
    def reflection_payload(quest_title, reflection, domains, leash):
        if not leash.is_allowed(IntegrationCategory.NOTES):
            return None
        if not reflection.strip():
            return None
        domain_line = f"\n_Threads: {', '.join(domains)}_\n" if domains else ""
        return (
            f"# Weave: {quest_title}{domain_line}\n\n"
            "## Reflection\n\n"
            f"{reflection.strip()}\n\n---\n"
            "Captured in OneWeave."
        )

    @staticmethod
    def decision_payload(scenario_summary, reflection, leash):
        if not leash.is_allowed(IntegrationCategory.NOTES):
            return None
        if not reflection.strip():
            return None
        s = scenario_summary.strip()
        scenario_block = f"## Scenario\n\n{s}\n\n" if s else ""
        return (
            "# Weave Decision\n\n"
            f"{scenario_block}## Why I chose this\n\n"
            f"{reflection.strip()}\n\n---\n"
            "Captured in OneWeave."
        )

    @staticmethod
    def snapshot_payload(title, summary, leash):
        if not leash.is_allowed(IntegrationCategory.NOTES):
            return None
        if not summary.strip():
            return None
        return f"# {title}\n\n{summary.strip()}\n\n---\nOneWeave snapshot."


class RemindersIntegrationLite:
    @staticmethod
    def create_reminder(title, reflection, leash):
        if not reflection.strip():
            return False  # reflection gate
        if not leash.is_allowed(IntegrationCategory.REMINDERS):
            return False
        return True


def main():
    strict = DataLeashState.strict_default()
    open_ = DataLeashState.fully_open()

    results = {}

    # 1. composeURL: nil when blocked
    results["mail_url_blocked"] = (
        MailIntegrationLite.compose_url("a@b.com", "s", "b", strict) is None
    )
    # 2. composeURL: URL when allowed
    url = MailIntegrationLite.compose_url("a@b.com", "s", "b", open_)
    results["mail_url_open"] = url is not None and url.startswith("mailto:")
    # 3. composeURL: nil for empty recipient
    results["mail_url_empty_recipient"] = (
        MailIntegrationLite.compose_url("", "s", "b", open_) is None
    )
    # 4. insightBody: nil for empty reflection
    results["mail_insight_empty_reflection"] = (
        MailIntegrationLite.insight_body("Title", "   ", open_) is None
    )
    # 5. insightBody: nil when leash blocks
    results["mail_insight_leash_denied"] = (
        MailIntegrationLite.insight_body("Title", "real", strict) is None
    )
    # 6. insightBody: String when allowed + reflection
    body = MailIntegrationLite.insight_body("Title", "real reflection", open_)
    results["mail_insight_ok"] = body is not None and "real reflection" in body

    # 7. decisionBody: requires reflection
    results["mail_decision_empty"] = (
        MailIntegrationLite.decision_body("s", "", open_) is None
    )
    # 8. decisionBody: blocked by leash
    results["mail_decision_leash_denied"] = (
        MailIntegrationLite.decision_body("s", "r", strict) is None
    )
    # 9. decisionBody: works when allowed
    decision = MailIntegrationLite.decision_body("Two offers", "Going smaller", open_)
    results["mail_decision_ok"] = decision is not None and "Going smaller" in decision

    # 10. Notes reflectionPayload: empty blocked
    results["notes_reflection_empty"] = (
        NotesIntegrationLite.reflection_payload("Call mom", "", ["CareKin"], open_) is None
    )
    # 11. Notes reflectionPayload: leash blocked
    results["notes_reflection_leash_denied"] = (
        NotesIntegrationLite.reflection_payload("Call mom", "real", ["CareKin"], strict) is None
    )
    # 12. Notes reflectionPayload: works when allowed
    note = NotesIntegrationLite.reflection_payload(
        "Call mom", "Felt great", ["CareKin"], open_
    )
    results["notes_reflection_ok"] = note is not None and "Felt great" in note

    # 13. Notes decisionPayload: empty blocked
    results["notes_decision_empty"] = (
        NotesIntegrationLite.decision_payload("s", "", open_) is None
    )
    # 14. Notes decisionPayload: leash blocked
    results["notes_decision_leash_denied"] = (
        NotesIntegrationLite.decision_payload("s", "r", strict) is None
    )
    # 15. Notes decisionPayload: works when allowed
    nd = NotesIntegrationLite.decision_payload("Scenario", "Why", open_)
    results["notes_decision_ok"] = nd is not None and "Why" in nd

    # 16. Notes snapshotPayload: empty blocked
    results["notes_snapshot_empty"] = (
        NotesIntegrationLite.snapshot_payload("title", "", open_) is None
    )
    # 17. Notes snapshotPayload: works
    snap = NotesIntegrationLite.snapshot_payload("Q1", "Reflected well", open_)
    results["notes_snapshot_ok"] = snap is not None and "Reflected well" in snap
    # 18. Notes snapshotPayload: leash blocks
    results["notes_snapshot_leash_denied"] = (
        NotesIntegrationLite.snapshot_payload("x", "y", strict) is None
    )

    # 19. Reminders createReminder: empty reflection blocked
    results["reminders_create_empty_reflection"] = (
        RemindersIntegrationLite.create_reminder("Call mom", "", open_) is False
    )
    # 20. Reminders createReminder: leash blocked
    results["reminders_create_leash_denied"] = (
        RemindersIntegrationLite.create_reminder("Call mom", "real", strict) is False
    )
    # 21. Reminders createReminder: works when allowed + reflection
    results["reminders_create_ok"] = (
        RemindersIntegrationLite.create_reminder("Call mom", "real reflection", open_) is True
    )

    print("=" * 60)
    print("Tier A #2 (Mail/Notes/Reminders gate logic) Validation")
    print("=" * 60)
    all_pass = True
    for name, passed in results.items():
        mark = "PASS" if passed else "FAIL"
        if not passed:
            all_pass = False
        print(f"  [{mark}] {name}")
    print("=" * 60)
    print(f"OVERALL: {'PASS' if all_pass else 'FAIL'}")
    print(f"  Tests: {len(results)} passed / {sum(1 for v in results.values() if v)} / {len(results)}")
    print("=" * 60)
    return 0 if all_pass else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())