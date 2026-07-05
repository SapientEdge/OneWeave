#!/usr/bin/env python3
"""subagent_wrapper.py — Per-sub-agent timing wrapper for cycle 47.

Lesson 35.5 context: Across cycles 45-46, 5 sub-agents appeared "hung" at
5+ minutes but had actually completed + committed. To diagnose, we wrap
every sub-agent invocation and record start/end ISO timestamps, wall-clock
duration, exit code, prompt path, log path. One JSON line per invocation
to data/subagents.jsonl. Lesson 35.5 cares about two stdout markers:
WRAPPER_STARTED (before) and WRAPPER_COMPLETED <duration>s (after), which
hung_detector.py greps for. Usage: subagent_wrapper.py <prompt> <log> --
<cmd...>. Stdlib only. No oneweave imports. No git operations.
"""

import json, subprocess, sys, time
from datetime import datetime, timezone
from pathlib import Path

DATA = Path(__file__).parent / "data"
JSONL = DATA / "subagents.jsonl"


def now_iso():
    return datetime.now(timezone.utc).isoformat()


def usage():
    print("Usage: subagent_wrapper.py <prompt_file> <log_file> -- <command...>\n"
          "Records timing + exit code to data/subagents.jsonl (one JSON line).")


def main(argv):
    args = argv[1:]
    if not args or args[0] in ("-h", "--help"):
        usage(); return 0
    if "--" not in args:
        sys.stderr.write("ERROR: missing '--'\n"); usage(); return 2
    sep = args.index("--")
    if sep < 2 or sep == len(args) - 1:
        sys.stderr.write("ERROR: need <prompt_file> <log_file> -- <command...>\n")
        usage(); return 2

    prompt, log, cmd = args[0], args[1], args[sep + 1:]
    DATA.mkdir(parents=True, exist_ok=True)
    Path(log).parent.mkdir(parents=True, exist_ok=True)

    start_ts, t0 = now_iso(), time.monotonic()
    print("WRAPPER_STARTED", flush=True)
    lf = open(log, "ab", buffering=0)
    try:
        rc = subprocess.run(cmd, stdin=subprocess.DEVNULL,
                            stdout=lf, stderr=subprocess.STDOUT).returncode
    except FileNotFoundError as e:
        sys.stderr.write(f"ERROR: {e}\n"); rc = 127
    except OSError as e:
        sys.stderr.write(f"ERROR: {e}\n"); rc = 126
    finally:
        lf.close()

    duration = round(time.monotonic() - t0, 3)
    print(f"WRAPPER_COMPLETED {duration}s", flush=True)
    rec = {"prompt_file": prompt, "log_file": log, "command": cmd,
           "start_ts": start_ts, "end_ts": now_iso(),
           "duration_s": duration, "exit_code": rc}
    try:
        with open(JSONL, "a", encoding="utf-8") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    except OSError as e:
        sys.stderr.write(f"WARN: {e}\n")
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))