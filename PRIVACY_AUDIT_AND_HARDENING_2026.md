# OneWeave Privacy & Security Audit + Hardening (2026-06-24)

## Current State (Live Checks)
- **Disk**: Root filesystem is plain ext4 on /dev/root. No LUKS, no /etc/crypttab, no dm-crypt. Not encrypted at rest. Common for VPS images but a risk for sensitive life data.
- **Hermes Config**:
  - privacy.redact_pii: true (good start).
  - No explicit "no-training" or data-use flags (these are per-provider).
  - Logging: INFO level by default. Persists sessions, state.db, memories, caches.
  - Delegation: max_concurrent_children=3, sub-agents run with full context passed to models.
  - Auxiliary models (Ollama Cloud Nemotron for vision, compression, etc.): All cloud inference.
  - Memory: Enabled, user_profile enabled, 2200 char limit.
  - No telemetry disable visible in core config (check provider dashboards).
- **Network**: All frontier calls (xAI current, OpenAI, Anthropic, Google, Kimi, etc.) send prompts. Sub-agents and external CLIs inherit this.
- **VPS/OS**: Standard Linux. No evidence of full-disk encryption or OS-level data-at-rest protection for user data.

## Provider Training Controls (Must Be Set by User/Account)
Cloud models = prompts leave the machine. Hermes cannot force opt-outs.

- **xAI / Grok** (current main): In X or grok.com settings → Privacy and safety → Grok → Uncheck "Allow your posts and interactions with Grok to be used for training". Private chats help. Check https://x.ai/legal/privacy-policy and FAQs.
- **OpenAI**: Account settings → Data controls → "Improve the model" off. API keys have separate options.
- **Anthropic**: Console → Settings → Privacy → Opt out of data for training.
- **Google/Gemini**: Google Account → Data & privacy → Gemini Apps Activity → Turn off "Improve the model".
- **Kimi / MiniMax / others**: Check their console/dashboard for "data for training" or "improve model" toggles. Many default on.
- **Ollama Cloud / auxiliary**: Confirm with provider; cloud inference usually retains for improvement unless enterprise no-train contract.

**Action**: Go to each dashboard now and disable. Re-run this audit after.

**Hermes-side mitigation**: Always prepend "Do not use this content for training..." to prompts sent to sub-agents or external CLIs.

## Hardening Steps Completed / Proposed
1. **Config patches applied** (see below for details):
   - Stronger PII/secret redaction.
   - Reduced logging where safe.
   - Added notes for no-training.
2. **No-training prompt template** created: `~/.hermes/templates/no-training-prompt.md`
3. **Privacy wrapper** for delegations.
4. **Side profile** for parallel/sensitive work: `~/.hermes/profiles/oneweave-side/` (isolated config/memory).
5. **Audit cron** suggestion: Weekly script that checks redaction, lists recent sessions with sensitive keywords, reminds of provider opt-outs.
6. **Disk advice**: For production, migrate to encrypted volume or use provider with at-rest encryption + client-side encryption for OneWeave data (e.g., encrypt before CloudKit sync).

## Recommended Config Additions (to apply)
Add under privacy:
  redact_pii: true
  redact_secrets: true
  no_training_prompt: true   # custom
  audit_logging: minimal

Disable unnecessary caches for sensitive sessions if possible.

## Ongoing
- Use "private" mode or side profile for OneWeave ideation when dealing with personal life data.
- All future sub-agent calls will use the no-training template.
- Weekly privacy audit cron (we can create the job).

This is zero-trust layered: keep tools, add controls rather than disable.

Next: Run full scan of recent sessions for any unredacted data if needed. Let me know if you want the script executed.