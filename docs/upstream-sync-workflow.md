# Upstream Sync Workflow

This document describes the exact procedure to pull updates from official sunnypilot into
the `ericbranan/TiguanSunnyPilot` fork without losing custom changes.

**Always read this document before syncing. Do not sync if the device is actively in use
or if you are mid-development on a critical change.**

---

## Remote Setup (Already Done)

Verify remotes before every sync:

```bash
git remote -v
```

Expected output:
```
origin     https://github.com/ericbranan/TiguanSunnyPilot.git  (fetch)
origin     https://github.com/ericbranan/TiguanSunnyPilot.git  (push)
upstream   https://github.com/sunnypilot/sunnypilot.git        (fetch)
upstream   DISABLED                                              (push)
```

If `upstream` is missing, re-add it:
```bash
git remote add upstream https://github.com/sunnypilot/sunnypilot.git
git remote set-url --push upstream DISABLED
```

---

## Step 1 — Save Current Work

Ensure all custom work is committed on the appropriate feature branch.

```bash
git status
git branch --show-current
```

If there are uncommitted changes:
```bash
git add -p          # stage relevant changes only, review each hunk
git commit -m "wip: save before upstream sync"
```

Push current work to origin:
```bash
git push origin custom/eric-main
git push origin custom/tiguan-ui
git push origin custom/tiguan-params
```

---

## Step 2 — Fetch Upstream

```bash
git fetch upstream --no-tags
```

For the first fetch, this will take significant time (sunnypilot is a large codebase with many submodules). Subsequent fetches are incremental.

To also fetch submodule refs:
```bash
git fetch upstream --recurse-submodules=no  # fetch main repo only first
```

---

## Step 3 — Review What Changed Upstream

Before applying anything, review what changed:

```bash
git log sunny-upstream..upstream/master --oneline --no-merges
```

Review the diff summary:
```bash
git diff sunny-upstream..upstream/master --stat
```

Check for changes in safety-critical areas (exit immediately if these changed unexpectedly):
```bash
git diff sunny-upstream..upstream/master -- panda/ selfdrive/car/volkswagen/ opendbc_repo/
```

Check for changes to files you have customized:
```bash
git diff sunny-upstream..upstream/master -- selfdrive/ui/ sunnypilot/
```

---

## Step 4 — Update the Clean Tracking Branch

`sunny-upstream` must be a fast-forward of `upstream/master`. No custom commits live here.

```bash
git checkout sunny-upstream
git merge --ff-only upstream/master
```

If `--ff-only` fails, the branch has diverged (should never happen — investigate before proceeding):
```bash
git log --oneline --graph -20
```

---

## Step 5 — Rebase Custom Branches

Each custom branch is rebased onto the updated `sunny-upstream`. This replays your
custom commits on top of the new upstream base.

### Rebase custom/tiguan-ui
```bash
git checkout custom/tiguan-ui
git rebase sunny-upstream
```

If rebase conflicts arise:
```bash
# For each conflicting file:
# 1. Open the file and resolve markers
# 2. git add <resolved-file>
# 3. git rebase --continue
# If you need to abort: git rebase --abort
```

### Rebase custom/tiguan-params
```bash
git checkout custom/tiguan-params
git rebase sunny-upstream
```

---

## Step 6 — Rebuild custom/eric-main

`custom/eric-main` is the integrated branch that will run on the device. Rebuild it
from the updated custom branches.

```bash
git checkout custom/eric-main
git rebase sunny-upstream
```

Then merge in the rebased feature branches (if they are not already part of eric-main):
```bash
git merge --no-ff custom/tiguan-ui -m "merge: tiguan-ui after upstream sync"
git merge --no-ff custom/tiguan-params -m "merge: tiguan-params after upstream sync"
```

---

## Step 7 — Run Checks

At minimum, check Python syntax on changed files:
```bash
python3 -m py_compile selfdrive/ui/*.py 2>&1 | head -20
```

If the sunnypilot test environment is set up:
```bash
# Run sunnypilot's own lint check (if tools are available)
python3 -m pylint selfdrive/car/volkswagen/ --errors-only
```

Search for any accidentally staged secrets:
```bash
git diff HEAD | grep -iE "(token|secret|password|api_key|private_key)" | head -20
```

---

## Step 8 — Push to origin Only

```bash
git push origin sunny-upstream
git push origin custom/tiguan-ui
git push origin custom/tiguan-params
git push origin custom/eric-main
```

**Never use `git push upstream` — the push URL is disabled, but double-check:**
```bash
git remote get-url --push upstream
# Expected: DISABLED
```

---

## Step 9 — Update Device

Only after the above steps pass:

1. Review the diff between old `custom/eric-main` and new one
2. Note any changes to VW-specific files or UI files
3. If everything looks correct, proceed to device update

See `docs/device-install-and-rollback.md` for the exact device update procedure.

---

## Frequency

- **When to sync:** After sunnypilot publishes a new release, or when a specific upstream
  fix is needed for your device.
- **When NOT to sync:** During a road trip, immediately before driving, or when you
  haven't reviewed the upstream changes.
- **Recommended cadence:** Monthly, or after each sunnypilot major release.

---

## Conflict Resolution Tips

| Conflict Type | Approach |
|---|---|
| UI file changed upstream AND in your branch | Review both sides carefully. Keep upstream structure, apply your UI change on top. |
| VW car interface file changed upstream | Accept upstream version entirely — do not customize VW car interface files. |
| Parameter default changed upstream | Evaluate whether your override is still appropriate. |
| panda/ or safety files changed | Accept upstream entirely. Never override safety code. |
| opendbc_repo submodule pointer changed | Update your submodule pointer to match upstream. Do not pin an old submodule. |

---

## Emergency: Discard All Custom Changes

If sync results in a broken state and you need to reset to clean sunnypilot:

```bash
git checkout sunny-upstream
git branch -D custom/eric-main  # DESTRUCTIVE — ensure everything is pushed first
git checkout -b custom/eric-main sunny-upstream
```

Then re-apply custom commits selectively:
```bash
git cherry-pick <commit-sha>
```
