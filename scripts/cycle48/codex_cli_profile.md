# Codex CLI Profile — T-Q1

Status: BLOCKED in this sandbox. `/root/.hermes` is read-only, so required Hermes-global artifacts could not be installed there. Running `codex exec --skip-git-repo-check` with the default home fails before prompt execution with `failed to initialize in-process app-server client: Read-only file system`. Re-running with `HOME=/tmp/codex_home` gets past startup but every invocation exits 1 after API transport retries because outbound network is blocked.

These are real measured failed-run timings, not successful LLM latency measurements.

## Timing Breakdown

| Prompt | Bytes | Exit | Cold start s | First content s | Total s |
|---|---:|---:|---:|---:|---:|
| echo hello | 11 | 1 | 0.196 | 0.195 | 31.064 |
| write a python hello world | 27 | 1 | 0.183 | 0.182 | 31.524 |
| write a 3-class python module with parse/summary/validate | 58 | 1 | 0.193 | 0.192 | 31.085 |
| write 3 python files: config parser, logger, pipeline | 54 | 1 | 0.173 | 0.173 | 30.448 |
| explain the difference between supervised and unsupervised learning | 68 | 1 | 0.192 | 0.191 | 30.683 |
| ONLY echo this exact fixed string and nothing else: CODEX_PROFILE_ECHO_ONLY | 76 | 1 | 0.189 | 0.188 | 30.937 |

## LLM vs Echo-Only

The echo-only prompt also exited 1 after 30.937s, matching the failed LLM prompts. This does not isolate CLI overhead from LLM work; it isolates environment transport retry time.

## Conclusion

No valid fraction of cycle 47's 5-40s baseline can be computed from this session. Observed pre-transport startup to first non-header output was about 0.173-0.196s, while total failed-run time averaged 30.957s because network retries dominated. A writable `/root/.hermes` and permitted OpenAI API access are required to complete T-Q1.2-T-Q1.4 without fabricating timings.
