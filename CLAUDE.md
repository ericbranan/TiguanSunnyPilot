# CLAUDE.md — TiguanSunnyPilot Fork Context

This file provides context for Claude Code sessions working on this repository.
Read this file in full before making any changes.

---

## What This Repository Is

A private personal customization fork of [sunnypilot](https://github.com/sunnypilot/sunnypilot)
for a 2022 Volkswagen Tiguan SE on a Comma 3X device.

**This is vehicle control software. Safety is the highest priority.**

Owner: Eric Branan (ericbranan/TiguanSunnyPilot)  
Vehicle: 2022 Volkswagen Tiguan SE (MQB platform)  
Hardware: Comma 3X  
Upstream: sunnypilot v2026.001.000+ (master branch)

---

## Repository Structure

```
/docs/                    — All fork documentation (read this first)
  eric-fork-overview.md   — Purpose, remotes, branch strategy, current status
  upstream-sync-workflow.md — How to pull sunnypilot updates safely
  device-install-and-rollback.md — How to install on Comma 3X / rollback
  sunnylink-notes.md      — SunnyLink dashboard capabilities and limits
  volkswagen-tiguan-research.md — VW Tiguan compatibility research
  customization-map.md    — What can/cannot be customized and at what risk
  safety-boundaries.md    — Hard safety rules — MUST READ before any change
  change-log.md           — Running log of all changes
CLAUDE.md                 — This file (session context for Claude Code)
```

The actual sunnypilot source code is NOT in this repository yet. The source code lives
upstream at `github.com/sunnypilot/sunnypilot` and will be incorporated when the full
development environment is set up. See `docs/eric-fork-overview.md` for the plan.

---

## Git Remotes

```
upstream   https://github.com/sunnypilot/sunnypilot.git   [fetch only — push is DISABLED]
origin     https://github.com/ericbranan/TiguanSunnyPilot  [fetch and push]
```

**CRITICAL:** Never push to upstream. Never push to `sunnypilot/sunnypilot`. Always verify
the remote before any push: `git remote get-url --push upstream` must return `DISABLED`.

---

## Branch Strategy

| Branch | Purpose |
|---|---|
| `sunny-upstream` | Clean mirror of upstream/master — no custom commits ever |
| `custom/tiguan-ui` | UI and visual customizations only |
| `custom/tiguan-params` | Default parameter and toggle changes |
| `custom/eric-main` | Integrated device branch — what runs on the Comma 3X |

---

## Safety Rules (Non-Negotiable)

Before making any change, read `docs/safety-boundaries.md`. Key rules:

1. **Never modify** `panda/` directory (hardware safety enforcement)
2. **Never modify** `selfdrive/controls/lib/*mpc*` files (MPC solvers)  
3. **Never modify** DBC files without upstream review
4. **Never disable** driver monitoring
5. **Never modify** vehicle fingerprints to spoof a different vehicle
6. **Never push** to upstream remote
7. **Never commit** tokens, keys, device IDs, or personal identifiers
8. **Never test** on public roads without completing the testing ladder in safety-boundaries.md

Acceptable changes in this fork:
- UI text, colors, layouts (LOW risk)
- Default parameter values for sunnypilot toggles (LOW risk)
- Audio assets (LOW risk)
- Tiguan-specific default preferences via params (LOW-MEDIUM risk)

---

## When Helping With This Repository

1. **Research before assuming** — check the relevant docs file for context
2. **Prefer documentation updates** over code changes until the source code is in the repo
3. **Check change-log.md** before making changes to understand history
4. **Follow the testing ladder** in safety-boundaries.md for any behavioral change
5. **If a change touches VW car interface or panda files**: stop and flag it — do not proceed
6. **For upstream syncs**: follow upstream-sync-workflow.md exactly

---

## Quick Reference — Useful Commands

```bash
# Check remote safety
git remote -v
git remote get-url --push upstream   # must return: DISABLED

# Check current branch
git branch --show-current

# See what's different from upstream (when upstream is fetched)
git log sunny-upstream..upstream/master --oneline

# Safe push
git push origin <branch-name>

# NEVER run
git push upstream <anything>   # push URL is disabled, but don't attempt it
```

---

## Relevant External Resources

- sunnypilot repo: https://github.com/sunnypilot/sunnypilot
- sunnypilot community: https://community.sunnypilot.ai
- sunnypilot docs: https://docs.sunnypilot.ai
- opendbc (VW code): https://github.com/commaai/opendbc
- openpilot VW wiki: https://github.com/commaai/openpilot/wiki/Volkswagen
- SunnyLink dashboard: https://sunnylink.ai/dashboard
- comma.ai harness shop: https://comma.ai/shop/car-harness
- Fork install URL format: install.sunnypilot.ai/fork/USERNAME/BRANCH
