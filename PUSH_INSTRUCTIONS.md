# OneWeave — How to Push to GitHub

*Step-by-step instructions for getting the Linux-validated code onto GitHub so Mac-Claude can pick it up.*

---

## Current state (verified 2026-06-27)

✓ Git repo initialized at `/root/hermes-workspace/projects/oneweave/` (branch `002-gamification`)
✓ Existing history (10+ commits) of the pre-validation code
✓ New files added but NOT yet committed (28 untracked Swift files, 16 validate_*.py, all the docs)
⚠ No remote configured yet
⚠ Changes from earlier session not yet committed

The repo is ready to commit + push, but the user should approve the commit message and remote URL before I run anything.

---

## What you need

1. **A GitHub account** — create at https://github.com if you don't have one
2. **An empty repo on GitHub** — create at https://github.com/new
   - Name suggestion: `oneweave` or `oneweave-private`
   - Visibility: **Private** (your call — code is yours)
   - Do NOT initialize with README/license/.gitignore (we have those)
3. **Authentication** — pick one:
   - **Personal Access Token (HTTPS)** — easier, fine for one-time push
   - **SSH key** — better long-term

---

## Step 1: Create the empty GitHub repo

Go to https://github.com/new

Settings:
- Repository name: `oneweave` (or your preference)
- Description: "Privacy-first Life OS for iOS"
- Visibility: **Private**
- ☐ Add a README file (UNCHECKED — we have one)
- ☐ Add .gitignore (UNCHECKED — we have one)
- ☐ Choose a license (UNCHECKED — we have MIT)

Click "Create repository"

Copy the URL — it'll look like one of:
- `https://github.com/YOUR_USERNAME/oneweave.git` (HTTPS)
- `git@github.com:YOUR_USERNAME/oneweave.git` (SSH)

---

## Step 2: Tell me which URL to use

You'll paste one of these in your next message:
- The HTTPS URL (and I'll prompt for the token when pushing), OR
- The SSH URL (after you've added my SSH key to your GitHub)

---

## Step 3: What I will do (NOT YET — waiting for your go-ahead)

Once you give the URL, I will:

1. Stage everything: `git add .`
2. Commit with a clear message summarizing what's in this push:
   ```
   Phase 1-5: 5 creative features + market research + Mac briefs
   
   5 new Swift files (CognitiveLoad, DailyBriefings, RelationshipDecayTracker,
   DecisionLog, QuickCaptureInbox) with 192+ tests across 5 new validation suites.
   
   Documentation: README, ARCHITECTURE, PRIVACY, CONTRIBUTING, FIRST_WEEK_ON_MAC,
   MARKET_RESEARCH_ROUND_3 (12.5KB positioning analysis).
   
   Total: 16 validation suites, 525+ tests, all green.
   ```
3. Set up the remote: `git remote add origin <your-url>`
4. Push: `git push -u origin 002-gamification` (or main, depending on what you want)
5. Verify the push: `git log` on the remote side via the GitHub web UI

---

## What I will NOT do

- ❌ Push to a public repo without explicit confirmation
- ❌ Force-push (would clobber existing history)
- ❌ Change your git config (name, email) without asking
- ❌ Add SSH keys to GitHub on your behalf (you do this on github.com)
- ❌ Make commits with `co-authored-by: Claude` (your repo, your attribution)

---

## After the push

Once the push is done, on the Mac side you'll do:

```bash
git clone https://github.com/YOUR_USERNAME/oneweave.git
cd oneweave
bash .research/validate_all.sh
# Expected: "✓ ALL SUITES PASS" with 16 suites
```

Then follow `FIRST_WEEK_ON_MAC.md` (the human-readable checklist) or `CLAUDE_COWORK_BRIEF.md` (the Claude cowork brief).

---

## If something goes wrong

| Problem | Fix |
|---------|-----|
| `git push` fails: "Authentication failed" | Token expired; generate new one. Or SSH key not added to GitHub. |
| `git push` fails: "Repository not found" | Wrong URL. Verify at github.com/YOUR_USERNAME/oneweave. |
| `git push` fails: "Updates were rejected" | Someone else pushed first. `git pull --rebase origin 002-gamification` then push. |
| "Permission denied (publickey)" | SSH key not in ssh-agent: `eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519` |

---

## Honest reminder

I have NOT yet committed the new files. They are sitting in `/root/hermes-workspace/projects/oneweave/` ready to be staged but not yet added. The `git status` shows them as "Untracked files."

When you're ready, tell me the URL. I'll handle staging, committing, and pushing. **No action taken yet.**

— Hermes, Linux, 2026-06-27