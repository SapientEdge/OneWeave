#!/usr/bin/env python3
import json, os, re, subprocess, sys, time
from pathlib import Path

OUT = Path(os.environ.get(
    "CODEX_PROFILE_OUT",
    str(Path.home() / ".hermes/scripts/cycle47/data/codex_profile.jsonl")))
DONE = re.compile(r"(tokens used|Done\.)", re.I)
SKIP = ("OpenAI Codex", "--------", "workdir:", "model:", "provider:",
        "approval:", "sandbox:", "reasoning effort:", "session id:")


def usage():
    print("Usage: codex_profiler.py <prompt-file> [-- <extra codex exec args>]")


def codex_version():
    try:
        p = subprocess.run(["codex", "--version"], text=True,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           timeout=10)
        return p.stdout.strip().splitlines()[-1]
    except Exception as e:
        return f"unknown: {e}"


def first_content(line):
    s = line.strip()
    if not s or s.startswith(("WARNING:", "Reading prompt from stdin")):
        return False
    return not any(s.startswith(x) for x in SKIP)


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        usage(); return 0
    prompt = Path(argv[1])
    extra = argv[argv.index("--") + 1:] if "--" in argv else []
    data = prompt.read_bytes()
    env = os.environ.copy()
    env["PYTHONUNBUFFERED"] = "1"
    cmd = ["codex", "exec", "--skip-git-repo-check", *extra]
    t0 = time.monotonic()
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, env=env,
                            bufsize=1)
    submit = time.monotonic()
    proc.stdin.write(data.decode("utf-8", "replace"))
    proc.stdin.close()
    first, done = None, None
    for line in proc.stdout:
        now = time.monotonic()
        if first is None and first_content(line):
            first = now
        if done is None and DONE.search(line):
            done = now
    rc = proc.wait()
    total = time.monotonic() - t0
    rec = {
        "prompt_file": str(prompt), "prompt_bytes": len(data),
        "codex_version": codex_version(), "exit_code": rc,
        "cold_start_s": round((done or first or t0) - t0, 3),
        "llm_round_trip_s": round((first or submit) - submit, 3),
        "total_s": round(total, 3),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("a", encoding="utf-8") as f:
        f.write(json.dumps(rec, sort_keys=True) + "\n")
    print(json.dumps(rec, sort_keys=True))
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))
