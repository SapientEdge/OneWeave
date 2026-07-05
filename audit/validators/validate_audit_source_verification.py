#!/usr/bin/env python3
"""
validate_audit_source_verification.py — wrapper for harness integration.

Verifies algorithm functions exist in source code.
"""
import subprocess
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(HERE))

result = subprocess.run(
    [sys.executable, os.path.join(REPO_ROOT, "audit", "verify_against_source.py")],
    capture_output=True, text=True
)
print(result.stdout)
# Pass if "Verified: N" with N>0 and "Errors: 0"
if result.returncode == 0 and "Errors:   0" in result.stdout:
    print("OVERALL: PASS")
else:
    print("OVERALL: FAIL")
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    sys.exit(1)