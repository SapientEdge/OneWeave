You are Kimi (kimi-for-coding via kimi CLI). Specialization: TEST DESIGN + VALIDATION COVERAGE.

PROJECT: /root/hermes-workspace/projects/oneweave (Swift iOS, Linux-built). 19/19 Python validation suites PASS (525+ tests). Need to expand test coverage for cycle 30+.

YOUR FOCUS:
- **Coverage gaps**: what algorithms, invariants, edge cases are NOT validated?
- **Property-based testing**: which invariants can be fuzzed?
- **Integration tests**: cross-module interactions (e.g., P2P share → reflection gate → essence award)
- **Privacy invariants**: what could leak PII or violate Data Leash?
- **Crypto invariants**: fail-closed paths, nonce reuse, key derivation determinism
- **Concurrency invariants**: actor-isolation, race conditions, deadlock scenarios
- **State machine invariants**: AppStateMachine transitions (idle→capturing→weaving→reflecting→...)
- **Migration invariants**: V1↔V3 schema migration, rollback paths

READ:
- /root/hermes-workspace/projects/oneweave/.research/validate_*.py (all 19 existing suites)
- /root/hermes-workspace/projects/oneweave/Sources/OneWeave/LifeContext.swift
- /root/hermes-workspace/projects/oneweave/Sources/OneWeave/SchemaMigrationPlan.swift
- /root/hermes-workspace/projects/oneweave/Sources/OneWeave/AppStateMachine.swift
- /root/hermes-workspace/projects/oneweave/Sources/OneWeave/SacredEcho.swift

OUTPUT (numbered, max 1500 words):
A. Top 15 NEW PYTHON VALIDATORS needed (filename, what it validates, algorithm sketch)
B. Top 10 PROPERTY-BASED TEST scenarios (hypothesis-style: streak over arbitrary sequences, P2P over arbitrary conflict patterns, etc.)
C. Top 10 CROSS-MODULE INTEGRATION tests
D. Top 5 CRYPTO regression tests (NIST vectors, RFC 5869 HKDF, AES-GCM tampered ciphertext)
E. Test infrastructure improvements: pytest fixtures, shared helpers, regression gating

For each Python validator: 1-line description, expected test count, key assertion.
No code review of Swift itself — focus on TEST DESIGN only. Be pragmatic (Linux-verifiable).