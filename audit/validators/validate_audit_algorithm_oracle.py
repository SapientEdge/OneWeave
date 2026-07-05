#!/usr/bin/env python3
"""
validate_audit_algorithm_oracle.py — wrapper for harness integration.

Re-runs the algorithm oracle and emits the harness-expected
"OVERALL: PASS" / "OVERALL: FAIL" markers.
"""
import subprocess
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))
# Wrapper lives in audit/validators/, so parent.parent is the repo root
REPO_ROOT = os.path.dirname(os.path.dirname(HERE))

result = subprocess.run(
    [sys.executable, os.path.join(REPO_ROOT, "audit", "algorithm_oracle.py")],
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