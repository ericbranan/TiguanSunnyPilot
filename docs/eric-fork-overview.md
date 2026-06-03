# Eric's TiguanSunnyPilot Fork — Overview

**Created:** 2026-06-03  
**Vehicle:** 2022 Volkswagen Tiguan SE (MQB platform, MK2)  
**Hardware:** Comma 3X  
**Based on:** sunnypilot `master` (v2026.001.000+)

---

## 1. Purpose

This is a personal customization fork of [sunnypilot](https://github.com/sunnypilot/sunnypilot)
for a single vehicle: a 2022 Volkswagen Tiguan SE on a Comma 3X device.

Goals:
- Make UI/UX adjustments that suit personal preference
- Adjust default parameter values for the Tiguan SE
- Track upstream sunnypilot safely to receive bug fixes and improvements
- Never push custom changes back to the official sunnypilot repository

This fork is for personal use only. It does not introduce novel vehicle behavior
changes — all ADAS functionality stays within openpilot/sunnypilot safety boundaries.

---

## 2. Repository Visibility

**Action required before adding device-specific material:**

The repository is currently **public** on GitHub. Before committing any device
identifiers, route data, personal notes, pairing codes, or SSH keys, decide on
the intended permanent state:

- **Public (current):** Anyone can read the repo. No personal identifiers or device
  IDs may ever be committed. Enables `install.sunnypilot.ai/fork/` install URL.
  Run a full secret and identifier scan before every push to `origin`.
- **Private:** Requires SSH-based device install (no URL installer). Allows more
  personal operational notes if kept generic. Set in GitHub → Settings → Danger Zone.

All documentation in this repo assumes the user has made this decision and acted on it.
No personal identifiers are present in the current committed files.

---

## 3. Upstream Repository

| Field | Value |
|---|---|
| Organization | sunnypilot |
| Repo | sunnypilot/sunnypilot |
| URL | https://github.com/sunnypilot/sunnypilot |
| Primary branch | `master` |
| C3X stable URL | release.sunnypilot.ai |
| C3X dev URL | dev.sunnypilot.ai |
| Fork install URL (public forks only) | install.sunnypilot.ai/fork/USERNAME/BRANCH |

---

## 4. Remote Configuration

```
upstream   https://github.com/sunnypilot/sunnypilot.git        (fetch)
upstream   DISABLED                                              (push — intentionally blocked)
origin     https://github.com/ericbranan/TiguanSunnyPilot.git  (fetch)
origin     https://github.com/ericbranan/TiguanSunnyPilot.git  (push)
```

The upstream push URL is set to `DISABLED`. A pre-push hook (`.githooks/pre-push`)
provides a second layer of protection. These are **local git config only** — they are
not stored in the repository. Every new clone must run `scripts/setup-git-safety.sh`.

Git safety settings (applied via setup script, not the repo):
```
push.default       = nothing  (all pushes require explicit remote:branch)
remote.pushDefault = origin
core.hooksPath     = .githooks
```

---

## 5. Branch Strategy

| Branch | Purpose | Based On |
|---|---|---|
| `sunny-upstream` | Clean tracking of upstream sunnypilot master. Never modified directly. | `upstream/master` |
| `custom/tiguan-ui` | UI and visual adjustments (LOW risk) | `sunny-upstream` |
| `custom/tiguan-params` | Default parameter and toggle changes (MEDIUM risk) | `sunny-upstream` |
| `custom/eric-main` | Integrated device branch — rebuilt after each sync, not rebased | merges from feature branches |

### Rules

- `sunny-upstream` is ONLY ever updated by fetching from `upstream`. No custom commits ever.
- `custom/tiguan-ui` and `custom/tiguan-params` are rebased onto `sunny-upstream` after an upstream sync.
- `custom/eric-main` is rebuilt (deleted and recreated) from `sunny-upstream` plus the rebased feature branches after each upstream sync — it is NOT rebased directly. See `docs/upstream-sync-workflow.md`.
- Never push any branch to `upstream`. The pre-push hook enforces this.

### Install Branch Note

The `install.sunnypilot.ai/fork/` installer parses the URL path and may not handle
forward-slash branch names correctly. If using the URL installer, maintain a separate
flat-named branch for device installs:

```
eric-main   ← a merge of custom/eric-main, pushed as a flat branch for URL installer use
```

If installing via SSH on the device, `custom/eric-main` works directly.

---

## 6. What This Fork May Change

- UI text labels, colors, icon assets (LOW risk)
- Default values for existing sunnypilot parameters/toggles (MEDIUM risk — document every change)
- Display layouts and onroad HUD elements (MEDIUM risk, UI code changes frequently upstream)
- Tiguan-specific default preferences via params (MEDIUM risk)

---

## 7. What This Fork Must NOT Change

- panda safety hooks and safety boundaries
- CAN message definitions or DBC files
- Steering torque limits or lateral tuning
- Longitudinal control code
- Driver monitoring disable or bypass
- Vehicle fingerprint identity
- openpilot boot sequence, watchdog, or update logic
- Any code preventing receipt of safety-critical upstream updates

See `docs/safety-boundaries.md` for the full policy.

---

## 8. How This Fork Stays Synced

1. Periodically fetch `upstream/master`
2. Fast-forward `sunny-upstream` to match `upstream/master`
3. Rebase `custom/tiguan-ui` and `custom/tiguan-params` onto updated `sunny-upstream`
4. Rebuild `custom/eric-main` from scratch (delete → recreate → merge feature branches)
5. Push updated branches to `origin` only, with explicit remote:branch
6. Install updated branch to device only after review and testing ladder passes

See `docs/upstream-sync-workflow.md` for exact commands.

---

## 9. Current Status

| Item | Status |
|---|---|
| Repo created | Yes — ericbranan/TiguanSunnyPilot (currently public — see §2) |
| Upstream remote added | Yes — push DISABLED, pre-push hook active |
| Git safety config | Yes — run `scripts/setup-git-safety.sh` on each new clone |
| Branch structure | Yes — all branches pushed to origin at initial commit |
| Default branch | `claude/practical-gates-T1eE1` — change to `sunny-upstream` when ready |
| Full upstream code fetched | No — do in dev environment with adequate storage (~1 GB+) |
| Custom code committed | No — pending initial device assessment |
| Device pointed to fork | No — pending fork readiness and testing ladder |
| Harness installed | Unknown — physically verify J533 connector before ordering |

---

## 10. First-Clone Setup (Required)

After cloning `ericbranan/TiguanSunnyPilot` on any new machine:

```bash
bash scripts/setup-git-safety.sh
```

This adds the upstream remote, disables its push URL, sets `push.default=nothing`,
and activates the pre-push hook. These settings live in `.git/config` (local only).
