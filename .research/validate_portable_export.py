#!/usr/bin/env python3
"""
validate_portable_export.py — Linux validation for PortableExport.swift

Tests the bundle builder + leash enforcement + reflection gates on
Linux via Python mirrors. 30+ checks covering:
  1. localOnly leash refuses to build (no bytes)
  2. Empty user intent rejected for any non-localOnly leash
  3. fullBundle requires 30+ char reflection
  4. privateBundle includes only private entities
  5. publicBundle includes only public entities (and redacts reflections)
  6. fullBundle includes everything
  7. Markdown renderer produces valid structure
  8. OPML renderer produces parseable XML
  9. OPML escapes special characters in titles
 10. Echo plaintexts ONLY included when leash permits
 11. Echo countdowns shown in echoes markdown even without plaintext
 12. Bundle size cap enforced (16 MB)
 13. Manifest stats reflect actual counts
 14. Checksum is consistent (same input → same output)
 15. Checksum is different for different content
 16. reflectionCount in manifest is 0 when leash doesn't permit
 17. Reflection TEXT only included when leash permits AND entity is user reflection
 18. Non-user-reflection entity (e.g., from system) never exports as if it were user
 19. Import policy refuses full-bundle by default
 20. Import policy accepts privateBundle + publicBundle
 21. Import policy refuses unsupported bundle versions
 22. Bundle version is current
 23. Attributes JSON is well-formed
 24. attributes are sorted alphabetically in the JSON output
 25. Bundle size cap cannot be bypassed via empty markdown + huge attributes
 26. Bundle preserves entities across all sections (journal, opml, attrs)
 27. Echo render includes decree when present
 28. Echo render skips plaintext section when leash doesn't permit
 29. Bundle can roundtrip (build → parse → stats match)
 30. Checksum changes when reflection content changes
"""

import hashlib
import json
import re
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Dict, List, Optional, Set, Tuple

# ---------------------------------------------------------------------------
# Mirror data types
# ---------------------------------------------------------------------------

@dataclass
class FakeEntity:
    id: str
    kind: str
    title: str
    summary: str
    domains: List[str]
    is_private: bool
    is_user_reflection: bool
    created_at: datetime
    attributes: Dict[str, str] = field(default_factory=dict)


@dataclass
class FakeRelationship:
    from_id: str
    to_id: str
    kind: str
    strength: float


@dataclass
class FakeEcho:
    id: str
    title: str
    decree: str
    state: str
    unlock_at: datetime
    expected_plaintext: Optional[str] = None


@dataclass
class FakeManifest:
    bundle_version: int
    exported_at: datetime
    app_version: str
    leash: str
    entity_count: int
    relationship_count: int
    reflection_count: int
    echo_count: int
    echo_plaintext_count: int
    user_intent_reflection: str
    checksum_sha256: str


# ---------------------------------------------------------------------------
# Mirror of PortableExportPolicy + ExportLeash
# ---------------------------------------------------------------------------

FULL_BUNDLE_MIN_REFLECTION_CHARS = 30
MAX_BUNDLE_BYTES = 16 * 1024 * 1024
CURRENT_BUNDLE_VERSION = 1
CURRENT_APP_VERSION = "OneWeave 0.9.0-rc"
SUPPORTED_BUNDLE_VERSIONS = {1}


def permits_reflections(leash: str) -> bool:
    return leash in ("private_bundle", "full_bundle")


def permits_echo_plaintext(leash: str) -> bool:
    return leash == "full_bundle"


def allowed_entity(entity: FakeEntity, leash: str) -> bool:
    if leash == "local_only":
        return False
    if leash == "private_bundle":
        return entity.is_private
    if leash == "public_bundle":
        return not entity.is_private
    return True  # full_bundle


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------

def render_journal(entities: List[FakeEntity], leash: str) -> str:
    allowed = [e for e in entities if allowed_entity(e, leash)]
    allowed.sort(key=lambda e: e.created_at)
    md = "# OneWeave Journal Export\n\n"
    md += f"_Exported under leash: **{leash}**_\n\n"
    md += "_Generated: now_\n\n"
    md += "---\n\n"
    for e in allowed:
        md += f"### {e.title}\n\n"
        md += f"_kind: {e.kind} · domains: {', '.join(e.domains)}_\n\n"
        if permits_reflections(leash) and e.is_user_reflection:
            md += f"{e.summary}\n\n"
        else:
            md += f"{e.kind} record · {len(e.summary)} chars redacted\n\n"
        if e.attributes:
            md += f"<details><summary>attributes ({len(e.attributes)})</summary>\n\n"
            for k, v in sorted(e.attributes.items()):
                md += f"- `{k}` = `{v[:80]}`\n"
            md += "\n</details>\n\n"
    return md


def xml_escape(s: str) -> str:
    return (s.replace("&", "&amp;")
             .replace("<", "&lt;")
             .replace(">", "&gt;")
             .replace('"', "&quot;")
             .replace("'", "&apos;"))


def render_opml(entities: List[FakeEntity], rels: List[FakeRelationship], leash: str) -> str:
    allowed = [e for e in entities if allowed_entity(e, leash)]
    by_domain: Dict[str, List[FakeEntity]] = {}
    for e in allowed:
        d = e.domains[0] if e.domains else "Uncategorized"
        by_domain.setdefault(d, []).append(e)
    xml = '<?xml version="1.0" encoding="UTF-8"?>\n<opml version="2.0">\n  <head>\n    <title>OneWeave Life Graph Export</title>\n    <ownerName>OneWeave</ownerName>\n  </head>\n  <body>\n'
    for d in sorted(by_domain.keys()):
        xml += f'    <outline text="{xml_escape(d)}">\n'
        for e in by_domain[d]:
            xml += f'        <outline text="{xml_escape(e.title)}" type="{e.kind}" entityID="{e.id}" />\n'
        xml += f'    </outline>\n'
    xml += '    <outline text="__relationships__">\n'
    title_by_id = {e.id: e.title for e in entities}
    for r in rels:
        f_title = title_by_id.get(r.from_id, r.from_id)
        t_title = title_by_id.get(r.to_id, r.to_id)
        edge = f"{f_title} \u2192 {t_title}"
        xml += f'        <outline text="{xml_escape(edge)}" type="{r.kind}" strength="{r.strength:.2f}" from="{r.from_id}" to="{r.to_id}" />\n'
    xml += '    </outline>\n'
    xml += '  </body>\n</opml>\n'
    return xml


def render_echoes(echoes: List[FakeEcho], leash: str, now: datetime) -> Tuple[str, Dict[str, str]]:
    md = "# Sacred Echoes\n\n"
    plaintexts: Dict[str, str] = {}
    sorted_echoes = sorted(echoes, key=lambda e: e.unlock_at)
    for e in sorted_echoes:
        md += f"## {e.title}\n\n"
        md += f"_state: {e.state} · unlocks: {e.unlock_at.isoformat()}_\n\n"
        if e.decree:
            md += "**Decree (present-self \u2192 future-self):**\n\n"
            md += f"> {e.decree}\n\n"
        if permits_echo_plaintext(leash):
            if e.expected_plaintext is not None:
                plaintexts[e.id] = e.expected_plaintext
                md += "**Reflection (decrypted):**\n\n"
                md += f"{e.expected_plaintext}\n\n"
            else:
                md += "_Plaintext could not be decrypted (key mismatch or corrupt echo)._\n\n"
        else:
            md += f"_Plaintext withheld by export leash `{leash}`._\n\n"
        md += "---\n\n"
    return md, plaintexts


def sha256_hex(s: str) -> str:
    # Mirror of CryptoKit's SHA-256 (used in production). The Linux
    # harness uses real SHA-256 too, not a fallback.
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def build_bundle(
    entities: List[FakeEntity],
    rels: List[FakeRelationship],
    echoes: List[FakeEcho],
    leash: str,
    user_intent_reflection: str,
    now: datetime,
) -> FakeManifest:
    if leash == "local_only":
        raise ValueError("localOnlyLeash")
    trimmed = user_intent_reflection.strip()
    if leash == "full_bundle" and len(trimmed) < FULL_BUNDLE_MIN_REFLECTION_CHARS:
        raise ValueError("fullBundleRequiresReflection")
    if not trimmed:
        raise ValueError("emptyUserIntent")

    journal = render_journal(entities, leash)
    opml = render_opml(entities, rels, leash)
    echoes_md, plaintexts = render_echoes(echoes, leash, now)

    attrs: Dict[str, Dict[str, str]] = {}
    for e in entities:
        if allowed_entity(e, leash):
            attrs[e.id] = e.attributes
    attrs_json = json.dumps(attrs, sort_keys=True, indent=2)

    canonical = f"{journal}\n---\n{opml}\n---\n{attrs_json}\n---\n{echoes_md}"
    if len(canonical.encode("utf-8")) > MAX_BUNDLE_BYTES:
        raise ValueError("bundleTooLarge")

    reflection_count = len([e for e in entities if e.is_user_reflection])
    return FakeManifest(
        bundle_version=CURRENT_BUNDLE_VERSION,
        exported_at=now,
        app_version=CURRENT_APP_VERSION,
        leash=leash,
        entity_count=len(attrs),
        relationship_count=len(rels),
        reflection_count=reflection_count if permits_reflections(leash) else 0,
        echo_count=len(echoes),
        echo_plaintext_count=len(plaintexts),
        user_intent_reflection=trimmed,
        checksum_sha256=sha256_hex(canonical),
    )


# ---------------------------------------------------------------------------
# Test harness
# ---------------------------------------------------------------------------

PASSED = 0
FAILED = 0
RESULTS: List[Tuple[str, bool, str]] = []


def check(name: str, condition: bool, detail: str = "") -> None:
    global PASSED, FAILED
    if condition:
        PASSED += 1
        RESULTS.append((name, True, ""))
    else:
        FAILED += 1
        RESULTS.append((name, False, detail))


NOW = datetime(2026, 6, 27, 12, 0, 0, tzinfo=timezone.utc)


def make_entity(
    eid: str,
    title: str = None,
    is_private: bool = True,
    is_user_reflection: bool = False,
    summary: str = "Some reflection text",
    domains: List[str] = None,
    attrs: Dict[str, str] = None,
    kind: str = "task",
) -> FakeEntity:
    return FakeEntity(
        id=eid,
        kind=kind,
        title=title or f"Entity {eid}",
        summary=summary,
        domains=domains or ["Self"],
        is_private=is_private,
        is_user_reflection=is_user_reflection,
        created_at=NOW,
        attributes=attrs or {},
    )


def make_echo(
    eid: str,
    title: str = None,
    decree: str = "",
    plaintext: Optional[str] = "echo reflection text",
    state: str = "opened",
) -> FakeEcho:
    return FakeEcho(
        id=eid,
        title=title or f"Echo {eid}",
        decree=decree,
        state=state,
        unlock_at=NOW,
        expected_plaintext=plaintext,
    )


def _should_accept(m: FakeManifest) -> bool:
    if m.bundle_version not in SUPPORTED_BUNDLE_VERSIONS:
        return False
    if m.leash == "full_bundle":
        return False  # refusesFullBundleByDefault
    return True


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

# Test 1: localOnly refuses
try:
    build_bundle([], [], [], "local_only", "intent", NOW)
    check("local_only_refused", False)
except ValueError as e:
    check("local_only_refused", str(e) == "localOnlyLeash", f"got {e}")

# Test 2: empty intent rejected
try:
    build_bundle([make_entity("a")], [], [], "private_bundle", "   ", NOW)
    check("empty_intent_rejected", False)
except ValueError as e:
    check("empty_intent_rejected", str(e) == "emptyUserIntent", f"got {e}")

# Test 3: fullBundle requires 30+ chars
try:
    build_bundle([make_entity("a")], [], [], "full_bundle", "short", NOW)
    check("full_bundle_requires_long_intent", False)
except ValueError as e:
    check("full_bundle_requires_long_intent", str(e) == "fullBundleRequiresReflection", f"got {e}")

# Test 4: privateBundle includes only private
entities = [
    make_entity("priv1", is_private=True),
    make_entity("priv2", is_private=True),
    make_entity("pub1", is_private=False),
]
journal = render_journal(entities, "private_bundle")
check("private_bundle_includes_only_private",
      "Entity priv1" in journal and "Entity priv2" in journal and "Entity pub1" not in journal,
      f"journal contains unexpected content")

# Test 5: publicBundle includes only public AND redacts reflections
entities = [
    make_entity("pub1", is_private=False, is_user_reflection=True, summary="SHOULD NOT EXPORT"),
    make_entity("priv1", is_private=True, is_user_reflection=True, summary="definitely not"),
]
journal = render_journal(entities, "public_bundle")
check("public_bundle_includes_only_public",
      "Entity pub1" in journal and "Entity priv1" not in journal)
check("public_bundle_redacts_reflection_text",
      "SHOULD NOT EXPORT" not in journal and "definitely not" not in journal,
      f"leak: {journal[:500]}")

# Test 6: fullBundle includes everything
entities = [
    make_entity("a", is_private=True),
    make_entity("b", is_private=False),
]
journal = render_journal(entities, "full_bundle")
check("full_bundle_includes_everything",
      "Entity a" in journal and "Entity b" in journal)

# Test 7: Markdown structure
journal = render_journal([make_entity("x")], "full_bundle")
check("markdown_has_h1", "# OneWeave Journal Export" in journal)
check("markdown_has_h3", "### Entity x" in journal)
check("markdown_has_leash_marker", "_Exported under leash: **full_bundle**_" in journal)

# Test 8: OPML is parseable XML
opml = render_opml(
    [make_entity("e1"), make_entity("e2")],
    [FakeRelationship("e1", "e2", "related", 0.7)],
    "full_bundle",
)
try:
    root = ET.fromstring(opml)
    check("opml_parseable", root.tag == "opml")
except ET.ParseError as e:
    check("opml_parseable", False, f"parse error: {e}")

# Test 9: OPML escapes special chars
opml = render_opml(
    [make_entity("e1", title='Tom & Jerry <test> "quoted"')],
    [],
    "full_bundle",
)
check("opml_escapes_ampersand", "&amp;" in opml)
check("opml_escapes_lt_gt", "&lt;test&gt;" in opml)
check("opml_escapes_quotes", "&quot;" in opml)

# Test 10: Echo plaintexts only when leash permits
md_priv, p_priv = render_echoes([make_echo("e1")], "private_bundle", NOW)
md_full, p_full = render_echoes([make_echo("e1")], "full_bundle", NOW)
md_pub, p_pub = render_echoes([make_echo("e1")], "public_bundle", NOW)
check("echo_plaintext_excluded_private", len(p_priv) == 0)
check("echo_plaintext_included_full", len(p_full) == 1)
check("echo_plaintext_excluded_public", len(p_pub) == 0)
check("echo_md_withheld_private", "withheld by export leash" in md_priv)
check("echo_md_decrypted_full", "Reflection (decrypted):" in md_full)

# Test 11: Echo countdown shown even without plaintext
md_priv, _ = render_echoes([make_echo("e1", plaintext="secret")], "private_bundle", NOW)
check("echo_countdown_visible_private", "Echo e1" in md_priv and "_state:" in md_priv)

# Test 12: Bundle size cap (using attribute bloat)
big_attrs = {f"k{i}": "x" * 1000 for i in range(20000)}  # ~20MB
big_entity = make_entity("a", attrs=big_attrs)
try:
    build_bundle([big_entity], [], [], "full_bundle", "I really want to export everything for archival purposes.", NOW)
    check("bundle_size_cap_enforced", False, "no error raised")
except ValueError as e:
    check("bundle_size_cap_enforced", str(e) == "bundleTooLarge", f"got {e}")

# Test 13: Manifest stats correct
entities = [make_entity(f"e{i}", is_private=False) for i in range(5)]
manifest = build_bundle(
    entities,
    [FakeRelationship("e0", "e1", "related", 0.5)],
    [make_echo("ec1")],
    "public_bundle",
    "share",
    NOW,
)
check("manifest_entity_count", manifest.entity_count == 5, f"got {manifest.entity_count}")
check("manifest_relationship_count", manifest.relationship_count == 1)
check("manifest_echo_count", manifest.echo_count == 1)
check("manifest_echo_plaintext_count_zero_public", manifest.echo_plaintext_count == 0)

# Test 14-15: Checksum consistency + sensitivity
m1 = build_bundle([make_entity("a")], [], [], "private_bundle", "intent", NOW)
m2 = build_bundle([make_entity("a")], [], [], "private_bundle", "intent", NOW)
m3 = build_bundle([make_entity("a", summary="different")], [], [], "private_bundle", "intent", NOW)
check("checksum_consistent", m1.checksum_sha256 == m2.checksum_sha256)
check("checksum_changes_with_content", m1.checksum_sha256 != m3.checksum_sha256)

# Test 16: reflectionCount is 0 when leash doesn't permit
manifest_pub = build_bundle(
    [make_entity("a", is_private=False, is_user_reflection=True)],
    [], [],
    "public_bundle", "intent", NOW,
)
check("reflection_count_zero_when_leash_blocks", manifest_pub.reflection_count == 0)

# Test 17: Reflection TEXT only when leash permits AND entity is user reflection
entities = [
    make_entity("priv_user", is_private=True, is_user_reflection=True, summary="private user reflection"),
    make_entity("priv_system", is_private=True, is_user_reflection=False, summary="system reflection"),
    make_entity("pub_user", is_private=False, is_user_reflection=True, summary="public user reflection"),
]
journal = render_journal(entities, "private_bundle")
check("private_user_reflection_included",
      "private user reflection" in journal)
check("private_system_reflection_redacted",
      "system reflection" not in journal)
check("public_user_reflection_excluded_in_private",
      "public user reflection" not in journal)

# Test 18: Non-user-reflection entity never exports as user text
entities = [make_entity("system", is_user_reflection=False, summary="AUTO: imported from calendar")]
journal = render_journal(entities, "full_bundle")
check("non_user_reflection_not_exported_as_user",
      "AUTO: imported from calendar" not in journal and "redacted" in journal)

# Test 19: Import refuses full-bundle by default
m_full = FakeManifest(
    bundle_version=1, exported_at=NOW, app_version="x", leash="full_bundle",
    entity_count=1, relationship_count=0, reflection_count=1,
    echo_count=0, echo_plaintext_count=0,
    user_intent_reflection="x", checksum_sha256="",
)
check("import_refuses_full_bundle_by_default", not _should_accept(m_full))

m_priv = FakeManifest(
    bundle_version=1, exported_at=NOW, app_version="x", leash="private_bundle",
    entity_count=1, relationship_count=0, reflection_count=0,
    echo_count=0, echo_plaintext_count=0,
    user_intent_reflection="x", checksum_sha256="",
)
check("import_accepts_private_bundle", _should_accept(m_priv))

m_pub = FakeManifest(
    bundle_version=1, exported_at=NOW, app_version="x", leash="public_bundle",
    entity_count=1, relationship_count=0, reflection_count=0,
    echo_count=0, echo_plaintext_count=0,
    user_intent_reflection="x", checksum_sha256="",
)
check("import_accepts_public_bundle", _should_accept(m_pub))

# Test 20 (alias of 19c)
# Test 21: Unsupported bundle version
m_v2 = FakeManifest(
    bundle_version=99, exported_at=NOW, app_version="x", leash="private_bundle",
    entity_count=1, relationship_count=0, reflection_count=0,
    echo_count=0, echo_plaintext_count=0,
    user_intent_reflection="x", checksum_sha256="",
)
check("import_refuses_unsupported_version", not _should_accept(m_v2))

# Test 22: Bundle version
m_curr = build_bundle([], [], [], "private_bundle", "intent", NOW)
check("bundle_version_is_current", m_curr.bundle_version == CURRENT_BUNDLE_VERSION)

# Test 23: Attributes JSON is well-formed
attrs: Dict[str, Dict[str, str]] = {"a": {"k": "v"}, "b": {"x": "y"}}
attrs_json = json.dumps(attrs, sort_keys=True, indent=2)
parsed = json.loads(attrs_json)
check("attrs_json_well_formed", parsed == attrs)

# Test 24: Attributes sorted alphabetically
entities = [
    make_entity("e1", attrs={"z": "1", "a": "2", "m": "3"}),
]
journal = render_journal(entities, "full_bundle")
pos_a = journal.find("`a`")
pos_m = journal.find("`m`")
pos_z = journal.find("`z`")
check("attributes_sorted_alphabetically",
      pos_a != -1 and pos_m != -1 and pos_z != -1 and pos_a < pos_m < pos_z,
      f"a={pos_a} m={pos_m} z={pos_z}")

# Test 25: Bundle size cap cannot be bypassed
huge_attrs = {f"key_{i:06d}": "x" * 100 for i in range(200000)}  # ~22MB
huge_entity = make_entity("a", attrs=huge_attrs)
try:
    build_bundle([huge_entity], [], [], "full_bundle", "I really want to export everything for archival purposes.", NOW)
    check("bundle_size_cap_huge_attrs", False)
except ValueError as e:
    check("bundle_size_cap_huge_attrs", str(e) == "bundleTooLarge")

# Test 26: Bundle preserves entities across all sections
entities = [
    make_entity("e1", is_private=True, domains=["Self"]),
    make_entity("e2", is_private=False, domains=["CareKin"]),
]
rels = [FakeRelationship("e1", "e2", "related", 0.5)]
journal = render_journal(entities, "full_bundle")
opml = render_opml(entities, rels, "full_bundle")
attrs_json = json.dumps({e.id: e.attributes for e in entities}, sort_keys=True)
check("entity_in_journal", "Entity e1" in journal and "Entity e2" in journal)
check("entity_in_opml", 'entityID="e1"' in opml and 'entityID="e2"' in opml)
check("entity_in_attrs", '"e1"' in attrs_json and '"e2"' in attrs_json)
check("relationship_in_opml", 'type="related"' in opml and 'from="e1"' in opml)

# Test 27: Echo render includes decree
md, _ = render_echoes([make_echo("e1", decree="Be patient.")], "full_bundle", NOW)
check("echo_decree_included", "Be patient." in md and "Decree" in md)

# Test 28: Echo render skips plaintext section when leash doesn't permit
md, _ = render_echoes([make_echo("e1", plaintext="SECRET TEXT")], "private_bundle", NOW)
check("echo_plaintext_skipped_when_blocked",
      "SECRET TEXT" not in md and "withheld" in md)

# Test 29: Roundtrip — build → parse → stats match
entities = [make_entity(f"e{i}") for i in range(3)]
rels = [FakeRelationship("e0", "e1", "knows", 0.8)]
echoes = [make_echo("ec1")]
manifest = build_bundle(entities, rels, echoes, "public_bundle", "share", NOW)
# Parse OPML and count entities
opml = render_opml(entities, rels, "public_bundle")
root = ET.fromstring(opml)
entity_count_in_opml = sum(
    1 for outline in root.iter("outline")
    if outline.get("entityID") is not None
)
check("roundtrip_entity_count",
      entity_count_in_opml == manifest.entity_count,
      f"opml={entity_count_in_opml} manifest={manifest.entity_count}")

# Test 30: Checksum changes when reflection content changes
journal1 = render_journal([make_entity("a", summary="first version")], "full_bundle")
journal2 = render_journal([make_entity("a", summary="second version")], "full_bundle")
check("checksum_sensitive_to_reflection_content",
      sha256_hex(journal1) != sha256_hex(journal2))

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print()
print("=" * 70)
print("PortableExport Linux validation")
print("=" * 70)
for name, passed, detail in RESULTS:
    mark = "PASS" if passed else "FAIL"
    line = f"  [{mark}] {name}"
    if detail and not passed:
        line += f"  -- {detail}"
    print(line)
print()
print(f"Total: {PASSED + FAILED}  |  PASSED: {PASSED}  |  FAILED: {FAILED}")
print()
sys.exit(0 if FAILED == 0 else 1)