#!/usr/bin/env python3
"""subagent_supervisor.py — cycle 47 R3: pre-flight + hung-detection wrapper.
Wraps subagent_wrapper.py + hung_detector.py with prompt pre-flight, concurrent
hung detector, marker counting, JSONL summary containing hung_during_run /
hung_max_elapsed_s / markers_emitted / preflight_passed. Stdlib only.
Usage: subagent_supervisor.py <prompt> <log> [--hung-threshold N] [--marker-required] -- <cmd...>
"""

import json, subprocess, sys, threading, time
from datetime import datetime, timezone
from pathlib import Path

H = Path(__file__).parent
WRAP, DET = H / "subagent_wrapper.py", H / "hung_detector.py"
DATA = H / "data"; MK, JL = DATA / "markers.log", DATA / "subagents.jsonl"


def iso(): return datetime.now(timezone.utc).isoformat()


def usage():
    print("Usage: subagent_supervisor.py <prompt> <log> [--hung-threshold 300] "
          "[--marker-required] -- <cmd...>\nWraps subagent_wrapper.py + hung_detector.py; "
          "records hung_during_run, markers_emitted, preflight_passed to data/subagents.jsonl.")


def parse(a):
    if not a or a[0] in ("-h", "--help"): return None
    if "--" not in a: sys.stderr.write("ERROR: missing '--'\n"); return None
    s = a.index("--")
    if s < 2 or s == len(a) - 1:
        sys.stderr.write("ERROR: need <prompt> <log> [--flags] -- <cmd...>\n"); return None
    p, lg, cmd, thr, mr = a[0], a[1], a[s+1:], 300, False
    i = 2
    while i < s:
        if a[i] == "--hung-threshold" and i+1 < s: thr = int(a[i+1]); i += 2
        elif a[i] == "--marker-required": mr = True; i += 1
        else: sys.stderr.write(f"ERROR: unknown arg {a[i]}\n"); return None
    return p, lg, thr, mr, cmd


def preflight(path, need):
    try: data = open(path, "rb").read()
    except OSError as e: return 0, False, f"PREFLIGHT_FAIL: cannot read prompt {path}: {e}"
    if need and b"marker.py" not in data:
        return len(data), False, ("PREFLIGHT_FAIL: prompt does not reference marker.py — add "
                                  "'python3 scripts/cycle47/marker.py start <task_id>' "
                                  "and 'end <task_id>' calls")
    return len(data), True, None


def count_markers(s_iso, e_iso):
    """Return (n, max_gap_seconds) for markers with ISO timestamp in [s_iso, e_iso]."""
    if not MK.exists(): return 0, 0.0
    n, prev, gap = 0, None, 0.0
    try:
        for line in open(MK, "r", encoding="utf-8"):
            parts = line.rstrip().split(" ", 3)
            if len(parts) < 4 or parts[0] != "CYCLE47_MARKER" or not (s_iso <= parts[3] <= e_iso):
                continue
            n += 1
            try:
                t = datetime.fromisoformat(parts[3]).timestamp()
                if prev is not None: gap = max(gap, t - prev)
                prev = t
            except ValueError: pass
    except OSError: pass
    return n, gap


def pump(proc, sink):
    for raw in iter(proc.stdout.readline, b""):
        try: sink(raw.decode("utf-8", "replace").rstrip())
        except Exception: sink(repr(raw))


def main(argv):
    args = argv[1:]; ps = parse(args)
    if ps is None:
        usage(); return 0 if (not args or args[0] in ("-h", "--help")) else 2
    prompt, log, thr, mr, cmd = ps
    DATA.mkdir(parents=True, exist_ok=True); Path(log).parent.mkdir(parents=True, exist_ok=True)

    t0, rs = time.monotonic(), iso()
    pb, ok, fail = preflight(prompt, mr)
    print(f"SUPERVISOR_STARTED prompt_bytes={pb}", flush=True)
    if not ok:
        print(fail, flush=True)
        rec = {"prompt_file": prompt, "log_file": log, "command": cmd, "start_ts": rs,
               "end_ts": iso(), "duration_s": 0.0, "exit_code": 2,
               "preflight_passed": False, "preflight_error": fail}
        try: open(JL, "a", encoding="utf-8").write(json.dumps(rec) + "\n")
        except OSError: pass
        return 2
    print("PREFLIGHT_OK", flush=True)

    wp = subprocess.Popen([sys.executable, str(WRAP), prompt, log, "--", *cmd],
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=1)
    dp = subprocess.Popen([sys.executable, str(DET), log, str(wp.pid),
                           "--threshold", str(thr), "--poll", "2"],
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=1)
    print(f"LAUNCHING_SUBAGENT pid={wp.pid}", flush=True)

    st = {"hung": False, "silence": 0.0, "crash": False, "wd": None}

    def ds(t):
        if t.startswith("HUNG_DETECTED"):
            st["hung"] = True
            try:
                p = t.split()
                if len(p) >= 3 and p[2].endswith("s"): st["silence"] = max(st["silence"], float(p[2][:-1]))
            except (ValueError, IndexError): pass
            print(t, flush=True)
        elif t.startswith("HUNG_OK"): print(t, flush=True)

    def ws(t):
        if t.startswith("WRAPPER_COMPLETED"):
            try: st["wd"] = float(t.split()[1].rstrip("s"))
            except (ValueError, IndexError): pass
        if t.startswith("WRAPPER_") or t.startswith("MARKER_EMITTED"): print(t, flush=True)

    threading.Thread(target=pump, args=(wp, ws), daemon=True).start()
    threading.Thread(target=pump, args=(dp, ds), daemon=True).start()
    wp.wait(); rc = wp.returncode
    det_clean = False
    try: dp.wait(timeout=2); det_clean = dp.returncode in (0, None)
    except subprocess.TimeoutExpired:
        dp.terminate()
        try: dp.wait(timeout=2)
        except subprocess.TimeoutExpired: dp.kill(); dp.wait()
    if not det_clean and dp.returncode not in (0, None, -15, -9) and not st["hung"]:
        st["crash"] = True; print(f"WARN: hung_detector exited rc={dp.returncode}", flush=True)

    re_ = iso(); total = round(time.monotonic() - t0, 3)
    print(f"SUBAGENT_EXITED duration={st['wd'] if st['wd'] is not None else 'unknown'}s", flush=True)
    print(f"HUNG_DURING_RUN: {'true' if st['hung'] else 'false'}", flush=True)
    mn, mg = count_markers(rs, re_); print(f"MARKERS_EMITTED: {mn}", flush=True)
    if st["hung"] and st["silence"] == 0.0: st["silence"] = float(thr)
    rec = {"prompt_file": prompt, "log_file": log, "command": cmd, "start_ts": rs,
           "end_ts": re_, "duration_s": st["wd"] if st["wd"] is not None else total,
           "exit_code": rc, "preflight_passed": ok, "hung_during_run": st["hung"],
           "hung_max_elapsed_s": int(round(max(st["silence"], mg))),
           "markers_emitted": mn, "hung_threshold_s": thr}
    if st["crash"]: rec["hung_detector_crash"] = True
    try: open(JL, "a", encoding="utf-8").write(json.dumps(rec) + "\n")
    except OSError as e: sys.stderr.write(f"WARN: jsonl append: {e}\n")
    print(f"SUPERVISOR_COMPLETED total_duration={total}s", flush=True)
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))