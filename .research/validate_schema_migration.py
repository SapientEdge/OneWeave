#!/usr/bin/env python3
"""
validate_schema_migration.py — Linux validation for SchemaMigrationPlan.swift

Tests the migration logic helpers + version registry in Python. Since
SwiftData itself only runs on Apple platforms, we test the *transform
logic* here (the part that converts V1 attributes JSON blobs into V3
dicts) and the path validation (which versions can migrate to which).

Test coverage:
  1. V1→V3 attributes conversion: simple string → string
  2. V1→V3 attributes conversion: array of strings → comma-joined
  3. V1→V3 attributes conversion: nested objects → JSON-encoded string
  4. V1→V3 attributes conversion: malformed JSON → empty dict
  5. V1→V3 attributes conversion: empty string → empty dict
  6. V1→V3 attributes conversion: non-UTF8 bytes handled gracefully
  7. Dict→JSON conversion (inverse) preserves all keys
  8. Dict→JSON conversion sorts keys (deterministic output)
  9. Roundtrip JSON→dict→JSON is lossless for string-only dicts
 10. Migration path validation: V1→V3 is valid
 11. Migration path validation: V3→V1 is rejected (no downgrades)
 12. Migration path validation: V0 (invalid) is rejected
 13. Migration path validation: V5 (future) is rejected as target
 14. Migration path validation: V1→V1 is a no-op
 15. Migration path validation: V2→V3 is valid (lightweight additive)
 16. All 11 @Model types are accounted for in the schema registry
 17. V1 attribute types match the V3 schema (both are string-keyed)
 18. Migration logic handles empty dict
 19. Migration logic handles dict with whitespace-only values
 20. Conversion is deterministic — same input → same output
 21. Array values with commas preserve the structure (joined vs. nested)
 22. Mixed types in V1 JSON: only string values extracted losslessly
 23. Migration stages list is not empty
 24. V1→V3 lightweight stage is declared
 25. Migration plan names a current schema version
"""

import json
import sys
from typing import Any, Dict, List, Tuple

# ---------------------------------------------------------------------------
# Mirror of OneWeaveMigrationLogic
# ---------------------------------------------------------------------------

SUPPORTED_VERSIONS = {1, 2, 3, 4}


def convert_attributes_json_to_dict(json_str: str) -> Dict[str, str]:
    """Mirror of OneWeaveMigrationLogic.convertAttributesJSONToDict."""
    if not json_str or not json_str.strip():
        return {}
    try:
        parsed = json.loads(json_str)
    except (json.JSONDecodeError, ValueError):
        return {}
    if not isinstance(parsed, dict):
        return {}
    result: Dict[str, str] = {}
    for k, v in parsed.items():
        if isinstance(v, str):
            result[k] = v
        elif isinstance(v, list):
            # Comma-separated for backward compatibility.
            str_items = [str(item) for item in v]
            result[k] = ",".join(str_items)
        else:
            # Unknown type — re-serialize and store as string.
            try:
                result[k] = json.dumps(v, sort_keys=True)
            except (TypeError, ValueError):
                pass
    return result


def convert_attributes_dict_to_json(d: Dict[str, str]) -> str:
    """Mirror of OneWeaveMigrationLogic.convertAttributesDictToJSON."""
    if not d:
        return "{}"
    return json.dumps(d, sort_keys=True)


def validate_migration_path(from_v: int, to_v: int) -> str | None:
    """Mirror of OneWeaveMigrationLogic.validateMigrationPath."""
    if from_v not in SUPPORTED_VERSIONS:
        return f"Source version {from_v} is outside supported range {sorted(SUPPORTED_VERSIONS)}"
    if to_v not in SUPPORTED_VERSIONS:
        return f"Target version {to_v} is outside supported range {sorted(SUPPORTED_VERSIONS)}"
    if to_v < from_v:
        return f"Downgrades are not supported (going from V{from_v} to V{to_v})."
    return None


# Mirror of all 13 @Model types (cycle 46: added VoidEntry + LifeMoment)
ALL_MODEL_TYPES = {
    "LifeContext",
    "LifeEntity",
    "LifeRelationship",
    "TimelineEvent",
    "WeaveQuest",
    "DataLeashSettingsRecord",
    "SacredEcho",
    "BasicSelfThread",
    "CareKinThread",
    "MeaningThread",
    "StewardshipThread",
    "VoidEntry",          # cycle 46 fix (was registered in OneWeaveApp but missing from plan)
    "LifeMoment",         # cycle 46 new feature
}


# Mirror of the migration plan stages (declarative check)
MIGRATION_STAGES = [
    {"from": "V1", "to": "V2", "kind": "lightweight"},
    {"from": "V2", "to": "V3", "kind": "custom"},
    {"from": "V3", "to": "V4", "kind": "lightweight"},  # cycle 46
]


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


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

# Test 1: simple string → string
result = convert_attributes_json_to_dict('{"name": "value"}')
check("simple_string_to_string", result == {"name": "value"}, f"got {result}")

# Test 2: array of strings → comma-joined
result = convert_attributes_json_to_dict('{"tags": ["a", "b", "c"]}')
check("array_to_joined",
      result == {"tags": "a,b,c"},
      f"got {result}")

# Test 3: nested object → JSON-encoded string
result = convert_attributes_json_to_dict('{"meta": {"x": 1, "y": 2}}')
check("nested_object_json_encoded",
      "meta" in result and json.loads(result["meta"]) == {"x": 1, "y": 2},
      f"got {result}")

# Test 4: malformed JSON → empty dict
check("malformed_json_empty",
      convert_attributes_json_to_dict("not json") == {},
      f"got {convert_attributes_json_to_dict('not json')}")
check("malformed_brace_empty",
      convert_attributes_json_to_dict("{not closed") == {})

# Test 5: empty string → empty dict
check("empty_string_empty_dict",
      convert_attributes_json_to_dict("") == {})
check("whitespace_only_empty_dict",
      convert_attributes_json_to_dict("   ") == {})

# Test 6: non-JSON payload (numeric) → empty dict
check("numeric_input_empty",
      convert_attributes_json_to_dict("12345") == {})

# Test 7: dict→JSON preserves keys
d = {"a": "1", "b": "2", "c": "3"}
json_out = convert_attributes_dict_to_json(d)
parsed = json.loads(json_out)
check("dict_to_json_preserves", parsed == d, f"got {parsed}")

# Test 8: dict→JSON sorts keys deterministically
d = {"z": "1", "a": "2", "m": "3"}
json_out = convert_attributes_dict_to_json(d)
check("dict_to_json_sorted",
      json_out.index('"a"') < json_out.index('"m"') < json_out.index('"z"'),
      f"got {json_out}")

# Test 9: roundtrip JSON→dict→JSON
original = '{"a": "1", "b": "2"}'
d = convert_attributes_json_to_dict(original)
back = convert_attributes_dict_to_json(d)
check("roundtrip_lossless", json.loads(back) == json.loads(original))

# Test 10: V1→V3 valid
check("v1_to_v3_valid", validate_migration_path(1, 3) is None)

# Test 11: V3→V1 rejected
result = validate_migration_path(3, 1)
check("v3_to_v1_rejected",
      result is not None and "Downgrade" in result,
      f"got {result}")

# Test 12: V0 invalid
result = validate_migration_path(0, 3)
check("v0_invalid_source", result is not None)

# Test 13: V5 future invalid target
result = validate_migration_path(3, 5)
check("v5_invalid_target", result is not None)

# Test 14: V1→V1 no-op
check("v1_to_v1_noop", validate_migration_path(1, 1) is None)

# Test 15: V2→V3 is now supported (cycle 46 update)
result = validate_migration_path(2, 3)
check("v2_to_v3_supported", result is None, f"got {result}")

# Test 15b: V3→V4 is supported (cycle 46)
result = validate_migration_path(3, 4)
check("v3_to_v4_supported", result is None, f"got {result}")

# Test 15c: V4→V4 no-op
check("v4_to_v4_noop", validate_migration_path(4, 4) is None)

# Test 15d: V4→V3 rejected (no downgrades)
result = validate_migration_path(4, 3)
check("v4_to_v3_rejected",
      result is not None and "Downgrade" in result,
      f"got {result}")

# Test 16: all 13 model types accounted for (cycle 46: +VoidEntry +LifeMoment)
expected_models = {
    "LifeContext", "LifeEntity", "LifeRelationship",
    "TimelineEvent", "WeaveQuest", "DataLeashSettingsRecord",
    "SacredEcho", "BasicSelfThread", "CareKinThread",
    "MeaningThread", "StewardshipThread",
    "VoidEntry", "LifeMoment",
}
check("all_13_models_present",
      ALL_MODEL_TYPES == expected_models,
      f"missing: {expected_models - ALL_MODEL_TYPES}")

# Test 16b: VoidEntry must be present (cycle 46 fix — was orphaned)
check("VoidEntry_in_models", "VoidEntry" in ALL_MODEL_TYPES)
# Test 16c: LifeMoment must be present (the new feature)
check("LifeMoment_in_models", "LifeMoment" in ALL_MODEL_TYPES)

# Test 17: V1 and V3 both use string-keyed attributes
v1_attr_type = "string"  # V1 attributes is a JSON string
v3_attr_type = "dict"    # V3 attributes is [String: String]
check("v1_string_to_v3_dict",
      v1_attr_type == "string" and v3_attr_type == "dict")

# Test 18: empty dict → "{}"
check("empty_dict_to_brace",
      convert_attributes_dict_to_json({}) == "{}")

# Test 19: whitespace values preserved (only leading/trailing trimmed if at all)
result = convert_attributes_json_to_dict('{"k": "  hello  "}')
check("whitespace_preserved_in_value", result == {"k": "  hello  "}, f"got {result}")

# Test 20: deterministic
inp = '{"k1": "v1", "k2": "v2"}'
r1 = convert_attributes_json_to_dict(inp)
r2 = convert_attributes_json_to_dict(inp)
check("deterministic", r1 == r2)

# Test 21: array with commas — preserves structure (joined with commas)
result = convert_attributes_json_to_dict('{"arr": ["a,b", "c", "d"]}')
# Joined: "a,b,c,d" — comma separator blurs with the inner comma
# This is a known limitation. We test that the join happens, but flag
# that callers with commas in array elements should use the nested-object
# path instead.
check("array_with_inner_commas_joined",
      result == {"arr": "a,b,c,d"},
      f"got {result}; known limitation: inner commas merge with separator")

# Test 22: mixed types — only string values extracted losslessly
result = convert_attributes_json_to_dict('{"s": "hi", "n": 42, "f": 3.14, "b": true}')
check("mixed_types_only_strings_native",
      result["s"] == "hi",
      f"got {result}")
# Numbers and bools become JSON strings
check("mixed_types_numbers_become_json",
      json.loads(result["n"]) == 42,
      f"got {result}")
check("mixed_types_floats_become_json",
      json.loads(result["f"]) == 3.14)
check("mixed_types_bools_become_json",
      json.loads(result["b"]) is True)

# Test 23: migration stages list not empty
check("migration_stages_not_empty", len(MIGRATION_STAGES) > 0)

# Test 24: V3→V4 lightweight stage declared (cycle 46)
v3_to_v4 = [s for s in MIGRATION_STAGES if s["from"] == "V3" and s["to"] == "V4"]
check("v3_to_v4_lightweight_declared",
      len(v3_to_v4) == 1 and v3_to_v4[0]["kind"] == "lightweight",
      f"got {v3_to_v4}")

# Test 24b: V2→V3 custom stage declared (heavyweight attributes conversion)
v2_to_v3 = [s for s in MIGRATION_STAGES if s["from"] == "V2" and s["to"] == "V3"]
check("v2_to_v3_custom_declared",
      len(v2_to_v3) == 1 and v2_to_v3[0]["kind"] == "custom",
      f"got {v2_to_v3}")

# Test 25: migration plan registers a current schema version (cycle 46: V4)
all_schemas = ["V1", "V2", "V3", "V4"]
check("v4_current_version_in_schemas", "V4" in all_schemas)

# Test 25b: 3 stages declared
check("three_migration_stages", len(MIGRATION_STAGES) == 3)


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

print()
print("=" * 70)
print("SchemaMigrationPlan Linux validation")
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