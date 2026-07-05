#!/usr/bin/env python3
"""marker.py — Cycle 47 marker emitter.

Lesson 35.5 context: Hung-vs-done ambiguity exists partly because sub-agents
print no explicit "task complete" marker. Codex may finish work, write
files, commit, then sit silent for minutes. Without a heartbeat marker,
external watchers cannot tell "buffered, still working" from "hung".
This script gives every sub-agent prompt a convention: emit a marker at
start, every checkpoint, and at end. Each call writes
`CYCLE47_MARKER <task_id> <action> <ISO>` to BOTH stdout (wrapper sees it)
AND data/markers.log (hung_detector + post-mortem see it). Also emits
MARKER_EMITTED <task_id> <action> to stdout for grep-based verification.
Action 'summary' prints all markers for a task_id. Stdlib only.
"""

import sys
from datetime import datetime, timezone
from pathlib import Path

DATA = Path(__file__).parent / "data"
SIDECAR = DATA / "markers.log"
ACTIONS = {"start", "end", "checkpoint"}


def now_iso():
    return datetime.now(timezone.utc).isoformat()


def usage():
    print("Usage: marker.py <start|end|checkpoint|summary> <task_id>\n"
          "Writes CYCLE47_MARKER lines to stdout + data/markers.log.")


def emit(task_id, action):
    DATA.mkdir(parents=True, exist_ok=True)
    line = f"CYCLE47_MARKER {task_id} {action} {now_iso()}"
    try:
        with open(SIDECAR, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except OSError as e:
        sys.stderr.write(f"WARN: {e}\n")
    print(line, flush=True)
    print(f"MARKER_EMITTED {task_id} {action}", flush=True)


def summary(task_id):
    if not SIDECAR.exists():
        print(f"No markers file at {SIDECAR}"); return 0
    n = 0
    try:
        with open(SIDECAR, "r", encoding="utf-8") as f:
            for line in f:
                if f" {task_id} " in line:
                    print(line.rstrip()); n += 1
    except OSError as e:
        sys.stderr.write(f"ERROR: {e}\n"); return 1
    if n == 0:
        print(f"No markers for task_id={task_id}")
    return 0


def main(argv):
    a = argv[1:]
    if not a or a[0] in ("-h", "--help"):
        usage(); return 0
    action = a[0]
    if action == "summary":
        if len(a) < 2:
            sys.stderr.write("ERROR: summary needs <task_id>\n"); usage(); return 2
        return summary(a[1])
    if action not in ACTIONS:
        sys.stderr.write(f"ERROR: action must be {sorted(ACTIONS)} or summary\n")
        usage(); return 2
    if len(a) < 2:
        sys.stderr.write("ERROR: missing <task_id>\n"); usage(); return 2
    emit(a[1], action)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))