#!/usr/bin/env python3
"""
validate_audit_algorithm_fuzz.py — wrapper for harness integration.

Re-runs the property-based fuzz tests (80,000+ random inputs).
"""
import subprocess
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(HERE))

result = subprocess.run(
    [sys.executable, os.path.join(REPO_ROOT, "audit", "algorithm_fuzz.py")],
    capture_output=True, text=True
)
print(result.stdout)
if result.returncode == 0:
    print("OVERALL: PASS")
else:
    print("OVERALL: FAIL")
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    sys.exit(1)