#!/usr/bin/env python3
"""Inventory all Swift algorithms across OneWeave sources."""
import re, os, json, sys

ROOT = "/root/hermes-workspace/projects/oneweave/Sources/OneWeave"

# Auto-discover all Swift files
ALGO_FILES = sorted([f for f in os.listdir(ROOT) if f.endswith(".swift")])

# Real directory listing
if not os.path.isdir(ROOT):
    print(f"ERROR: {ROOT} not found", file=sys.stderr)
    sys.exit(1)

inventory = []
for fname in ALGO_FILES:
    p = os.path.join(ROOT, fname)
    if not os.path.exists(p):
        inventory.append({"file": fname, "exists": False})
        continue
    with open(p) as f:
        text = f.read()
    lines = text.split("\n")
    funcs_with_return = re.findall(r'func\s+(\w+)\s*\([^)]*\)\s*->\s*([\w\?]+)', text)
    funcs_void = re.findall(r'^\s*func\s+(\w+)\s*\([^)]*\)\s*(?:->\s*[\w\?]+\s*)?\{', text, re.MULTILINE)
    math_lines = []
    for i, line in enumerate(lines, 1):
        if re.search(r'\b(exp|log|pow|sqrt|acos|asin|atan|atan2|sin|cos|tan)\s*\(', line):
            math_lines.append((i, line.strip()))
    inventory.append({
        "file": fname, "exists": True, "lines": len(lines),
        "funcs_with_return_count": len(funcs_with_return),
        "funcs_with_return_names": [f"{n}->{r}" for n,r in funcs_with_return],
        "funcs_void_count": len(funcs_void),
        "funcs_void_names": funcs_void,
        "math_lines_count": len(math_lines),
        "math_lines_sample": math_lines[:8],
    })

# Summary table
print(f"{'FILE':<50} {'LOC':>6} {'FN→':>5} {'FN_':>5} {'MATH':>5}")
print("-" * 76)
total_loc = total_math = total_fn_ret = total_fn_void = 0
for inv in sorted(inventory, key=lambda x: -(x.get("math_lines_count") or 0)):
    if not inv.get("exists"):
        print(f"{inv['file']:<50} {'MISSING':>6}")
        continue
    print(f"{inv['file']:<50} {inv['lines']:>6} {inv['funcs_with_return_count']:>5} {inv['funcs_void_count']:>5} {inv['math_lines_count']:>5}")
    total_loc += inv["lines"]
    total_math += inv["math_lines_count"]
    total_fn_ret += inv["funcs_with_return_count"]
    total_fn_void += inv["funcs_void_count"]
print("-" * 76)
print(f"{'TOTAL':<50} {total_loc:>6} {total_fn_ret:>5} {total_fn_void:>5} {total_math:>5}")

# Persist
os.makedirs("/root/hermes-workspace/projects/oneweave/.research/audit", exist_ok=True)
with open("/root/hermes-workspace/projects/oneweave/.research/audit/algorithm_inventory.json", "w") as f:
    json.dump(inventory, f, indent=2)
print(f"\nWrote .research/audit/algorithm_inventory.json ({len(inventory)} files)")