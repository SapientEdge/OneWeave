#!/usr/bin/env python3
"""hung_detector.py — Cycle 47 hung-vs-done detector (Lesson 35.5).
Tells "genuinely hung" from "finished but buffering". Polls a log. If no
new bytes AND no CYCLE47_MARKER / WRAPPER_* heartbeats in threshold
seconds, prints HUNG_DETECTED. Else HUNG_OK. Output to stdout +
data/hung.log. Usage: hung_detector.py <log> <pid> [--threshold 300]
[--poll 5]. Stdlib only. Runs forever until killed.
"""

import os, sys, time
from datetime import datetime, timezone
from pathlib import Path

DATA = Path(__file__).parent / "data"
HUNG_LOG = DATA / "hung.log"
HB = ("CYCLE47_MARKER ", "WRAPPER_STARTED", "WRAPPER_COMPLETED")


def now_iso():
    return datetime.now(timezone.utc).isoformat()


def usage():
    print("Usage: hung_detector.py <log> <pid> [--threshold 300] [--poll 5]\n"
          "HUNG_OK/cycle; HUNG_DETECTED if no bytes AND no heartbeats.")


def parse(argv):
    a = argv[1:]
    if not a or a[0] in ("-h", "--help"):
        usage(); return None
    log = a[0]; pid = a[1] if len(a) > 1 else "unknown"
    thr, poll, i = 300, 5, 2
    while i < len(a):
        if i + 1 >= len(a): break
        if a[i] == "--threshold": thr = int(a[i + 1]); i += 2
        elif a[i] == "--poll": poll = int(a[i + 1]); i += 2
        else: sys.stderr.write(f"ERROR: bad arg {a[i]}\n"); return None
    return log, pid, thr, poll


def main(argv):
    parsed = parse(argv)
    if not parsed: return 2
    log, pid, thr, poll = parsed
    DATA.mkdir(parents=True, exist_ok=True)
    print(f"hung_detector {log} pid={pid} thr={thr}s poll={poll}s", flush=True)
    try: last_sz = os.path.getsize(log)
    except OSError: last_sz = 0
    last_hb = t0 = time.monotonic(); was_hung = False
    while True:
        time.sleep(poll); now = time.monotonic()
        try: sz = os.path.getsize(log)
        except OSError: sz = last_sz
        grew = sz > last_sz; last_sz = max(last_sz, sz)
        if grew:
            try:
                with open(log, "rb") as f:
                    f.seek(max(0, last_sz - 65536))
                    if any(h in f.read().decode("utf-8", "replace") for h in HB):
                        last_hb = now
            except OSError: pass
        silence = now - last_hb; total = now - t0
        if silence >= thr:
            line = f"HUNG_DETECTED {pid} {silence:.1f}s {last_sz}"
            print(line, flush=True)
            with open(HUNG_LOG, "a", encoding="utf-8") as f:
                f.write(f"{now_iso()} {line}\n")
            was_hung = True
        else:
            print(f"HUNG_OK {pid} {total:.1f}s", flush=True)
            if was_hung:
                with open(HUNG_LOG, "a", encoding="utf-8") as f:
                    f.write(f"{now_iso()} HUNG_RECOVERED {pid}\n")
                was_hung = False


if __name__ == "__main__":
    try: sys.exit(main(sys.argv))
    except KeyboardInterrupt:
        print("interrupted", flush=True); sys.exit(0)