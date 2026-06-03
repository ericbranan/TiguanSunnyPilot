# Eric's TiguanSunnyPilot Fork — Overview

**Created:** 2026-06-03  
**Vehicle:** 2022 Volkswagen Tiguan SE (MQB platform, MK2)  
**Hardware:** Comma 3X  
**Based on:** sunnypilot `master` (v2026.001.000+)

---

## 1. Purpose

This is a private, personal customization fork of [sunnypilot](https://github.com/sunnypilot/sunnypilot) for a single vehicle: a 2022 Volkswagen Tiguan SE on a Comma 3X device.

Goals:
- Make UI/UX adjustments that suit personal preference
- Adjust default parameter values for the Tiguan SE
- Track upstream sunnypilot safely to receive bug fixes and improvements
- Never push custom changes back to the official sunnypilot repository

This fork is **not a public distribution**. It is for personal use only. It does not introduce novel vehicle behavior changes — all ADAS functionality stays within openpilot/sunnypilot safety boundaries.

---

## 2. Upstream Repository

| Field | Value |
|---|---|
| Organization | sunnypilot |
| Repo | sunnypilot/sunnypilot |
| URL | https://github.com/sunnypilot/sunnypilot |
| Primary branch | `master` |
| C3X stable URL | release.sunnypilot.ai |
| C3X dev URL | dev.sunnypilot.ai |
| Fork install URL | install.sunnypilot.ai/fork/USERNAME/BRANCH |

---

## 3. Remote Configuration

```
upstream   https://github.com/sunnypilot/sunnypilot.git   (fetch)
upstream   DISABLED                                         (push — intentionally blocked)
origin     https://github.com/ericbranan/TiguanSunnyPilot  (fetch)
origin     https://github.com/ericbranan/TiguanSunnyPilot  (push)
```

The upstream push URL is set to `DISABLED` to prevent accidental pushes to sunnypilot.

Git safety settings applied:
```
remote.pushDefault = origin
push.default = current
```

---

## 4. Branch Strategy

| Branch | Purpose | Based On |
|---|---|---|
| `sunny-upstream` | Clean tracking of upstream sunnypilot master. Never modified directly. | `upstream/master` |
| `custom/tiguan-ui` | UI and visual adjustments (low risk) | `sunny-upstream` |
| `custom/tiguan-params` | Default parameter and toggle changes (low-medium risk) | `sunny-upstream` |
| `custom/eric-main` | Integrated custom branch — this is what runs on the device | merges from above |

### Rules
- `sunny-upstream` is ONLY ever updated by fetching from `upstream`. No custom commits.
- `custom/tiguan-ui` and `custom/tiguan-params` are feature branches that are rebased onto `sunny-upstream` after an upstream update.
- `custom/eric-main` is the device branch — rebased or merged from the custom feature branches.
- **Never push any branch to `upstream`.**
- **Never push to `sunnypilot/sunnypilot`.**

---

## 5. What This Fork May Change

- UI text labels, colors, icon assets (low risk, no merge conflict expected)
- Default values for existing sunnypilot parameters/toggles (low risk if properly documented)
- Display layouts and onroad HUD elements (medium risk, UI code changes frequently)
- Tiguan-specific default preferences (e.g., lane centering mode, alert thresholds) if exposed as parameters

---

## 6. What This Fork Must NOT Change

- panda safety hooks and safety boundaries
- CAN message definitions or DBC files (unless adding official openpilot fingerprint support)
- Steering torque limits or lateral tuning beyond stock values
- Longitudinal control parameters (braking, acceleration profiles)
- Driver monitoring disable or bypass
- fingerprint spoofing or vehicle identity manipulation
- openpilot boot sequence, watchdog, or update logic
- Any code that would prevent the device from receiving safety-critical upstream updates

See `docs/safety-boundaries.md` for the full safety policy.

---

## 7. How This Fork Stays Synced

1. Periodically fetch `upstream/master`
2. Fast-forward `sunny-upstream` to match `upstream/master`
3. Rebase `custom/tiguan-ui` and `custom/tiguan-params` onto updated `sunny-upstream`
4. Rebuild `custom/eric-main` from the rebased feature branches
5. Push updated branches to `origin` only
6. Install updated branch to device only after review

See `docs/upstream-sync-workflow.md` for exact commands.

---

## 8. Current Status

| Item | Status |
|---|---|
| Private repo created | Yes — ericbranan/TiguanSunnyPilot |
| Upstream remote added | Yes — push disabled |
| Branch structure created | Yes — documented, initial commit pending |
| Full upstream code fetched | No — do this in dev environment (large repo) |
| Custom code committed | No — pending initial device assessment |
| Device pointed to fork | No — pending fork readiness |
| Harness installed | Unknown — must verify before proceeding |

---

## 9. Important Notes

- This repo's `ericbranan/TiguanSunnyPilot` is private on GitHub.
- The `install.sunnypilot.ai/fork/USERNAME/BRANCH` installer **requires the fork to be public** on GitHub.
- For a private fork, installation on device requires SSH (see `docs/device-install-and-rollback.md`).
- If the fork is made public, ensure no personal identifiers, tokens, or private keys are ever committed.
