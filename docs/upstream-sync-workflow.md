# Upstream Sync Workflow

This document describes the exact procedure to pull updates from official sunnypilot into
the `ericbranan/TiguanSunnyPilot` fork without losing custom changes.

**Always read this document before syncing. Do not sync if the device is actively
in use or if you are mid-development on a critical change.**

---

## Prerequisites — Verify Before Every Sync

```bash
# 1. Correct remotes
git remote -v
# Expected:
#   origin     https://github.com/ericbranan/TiguanSunnyPilot.git  (fetch)
#   origin     https://github.com/ericbranan/TiguanSunnyPilot.git  (push)
#   upstream   https://github.com/sunnypilot/sunnypilot.git        (fetch)
#   upstream   DISABLED                                              (push)

# 2. Push URL must be DISABLED
git remote get-url --push upstream

# 3. Safety config is active
git config push.default          # must print: nothing
git config remote.pushDefault    # must print: origin
git config core.hooksPath        # must print: .githooks
```

If any of these are missing, re-run `scripts/setup-git-safety.sh` before continuing.

If `upstream` is missing entirely:
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
git add -p          # stage relevant changes only; review each hunk carefully
git commit -m "wip: save before upstream sync"
```

Push current work to origin using explicit remote:branch (required by push.default=nothing):
```bash
git push origin custom/eric-main:custom/eric-main
git push origin custom/tiguan-ui:custom/tiguan-ui
git push origin custom/tiguan-params:custom/tiguan-params
```

---

## Step 2 — Fetch Upstream

```bash
# Fetch source commits only (--no-tags = no release tag annotations)
git fetch upstream --no-tags

# To also fetch sunnypilot release tags for changelog comparison:
git fetch upstream --tags
# Note: tags are fetched but do not affect the merge procedure.
```

First fetch is large (~1 GB including submodule history). Subsequent fetches are
incremental.

---

## Step 3 — Record Upstream State Before Applying

Before applying anything, record what is about to change. This is your comparison
baseline and should be saved to a scratch note (not committed).

```bash
# New commits in upstream since your last sync
git log sunny-upstream..upstream/master --oneline --no-merges

# Summary of files changed
git diff sunny-upstream..upstream/master --stat

# Submodule pointer changes (critical — record both SHA values)
git diff sunny-upstream..upstream/master -- .gitmodules
git diff sunny-upstream..upstream/master -- opendbc_repo panda

# Check for safety-critical area changes — investigate any hit before continuing
git diff sunny-upstream..upstream/master -- panda/ opendbc_repo/ selfdrive/controls/

# Check for changes in areas you have customized
git diff sunny-upstream..upstream/master -- selfdrive/ui/ sunnypilot/
```

If safety-critical files changed unexpectedly, stop and read the sunnypilot release
notes and community forum before proceeding.

---

## Step 4 — Update the Clean Tracking Branch

`sunny-upstream` must be a fast-forward of `upstream/master`. No custom commits live here.

```bash
git checkout sunny-upstream
git merge --ff-only upstream/master
```

If `--ff-only` fails (should never happen — investigate before proceeding):
```bash
git log --oneline --graph -20
```

---

## Step 5 — Check Submodule Status After Update

The upstream merge may have moved the `opendbc_repo` or `panda` submodule pointers.
Record the new submodule SHAs before rebasing feature branches.

```bash
# Record submodule state on the updated sunny-upstream
git submodule status --recursive

# Compare to what was there before (from your notes in Step 3)
# Accept upstream submodule pointer changes unless there is a reviewed reason not to.
```

---

## Step 6 — Rebase Custom Feature Branches

Each custom branch is rebased onto the updated `sunny-upstream`.

### Rebase custom/tiguan-ui
```bash
git checkout custom/tiguan-ui
git rebase sunny-upstream
```

### Rebase custom/tiguan-params
```bash
git checkout custom/tiguan-params
git rebase sunny-upstream
```

If rebase conflicts arise on either branch:
```bash
# For each conflicting file:
#   1. Open the file and resolve the conflict markers
#   2. git add <resolved-file>
#   3. git rebase --continue
# To abort and start over: git rebase --abort
```

**Conflict guidance by file type:**

| File type | Action |
|---|---|
| UI file changed upstream AND in your branch | Keep upstream structure; re-apply your delta on top |
| VW car interface file | Accept upstream entirely — do not carry custom changes here |
| Parameter default changed upstream | Evaluate whether your override is still appropriate |
| panda/ or safety files | Accept upstream entirely — never override safety code |
| opendbc_repo submodule pointer | Accept upstream pointer — do not pin old submodule |

---

## Step 7 — Rebuild `custom/eric-main` (Do Not Rebase)

`custom/eric-main` is an **integration branch** built by merging feature branches onto
`sunny-upstream`. After an upstream sync it must be **rebuilt from scratch**, not rebased.
Rebasing an integration branch replays old merge commits and creates confusing history.

```bash
# Save the current eric-main as a reference (optional but recommended)
git branch -m custom/eric-main custom/eric-main-old

# Build fresh from updated sunny-upstream
git checkout sunny-upstream
git checkout -b custom/eric-main

# Merge in each feature branch (already rebased in Step 6)
git merge --no-ff custom/tiguan-ui   -m "merge: tiguan-ui after upstream sync $(date +%Y-%m-%d)"
git merge --no-ff custom/tiguan-params -m "merge: tiguan-params after upstream sync $(date +%Y-%m-%d)"

# Force-push the rebuilt branch (--force-with-lease verifies no one else pushed)
git push --force-with-lease origin custom/eric-main:custom/eric-main

# After confirming the new branch is correct, delete the old reference
git branch -D custom/eric-main-old
```

---

## Step 8 — Run Checks

```bash
# Python syntax check on changed UI files (if source is present)
python3 -m py_compile selfdrive/ui/*.py 2>&1 | head -20

# Pylint on VW car interface (errors only, if source is present)
python3 -m pylint opendbc_repo/opendbc/car/volkswagen/ --errors-only 2>&1 | head -30

# Secret scan — use gitleaks for comprehensive coverage
# Install: pip3 install gitleaks  OR  brew install gitleaks
gitleaks detect --source . --no-git 2>&1 | head -30
# Also scan full git history after initial upstream fetch:
# gitleaks detect --source . 2>&1 | head -30
```

---

## Step 9 — Push to Origin Only

All pushes require explicit remote:branch because `push.default = nothing`.

```bash
git push origin sunny-upstream:sunny-upstream
git push origin custom/tiguan-ui:custom/tiguan-ui
git push origin custom/tiguan-params:custom/tiguan-params
git push origin custom/eric-main:custom/eric-main
# eric-main was already force-pushed in Step 7 — skip if already done
```

Verify before each push:
```bash
git remote get-url --push upstream   # Must print: DISABLED
```

---

## Step 10 — Record the Sync in change-log.md

Add an entry to `docs/change-log.md` with:
- Date
- Previous upstream commit SHA
- New upstream commit SHA
- New opendbc_repo submodule SHA
- New panda submodule SHA
- Summary of what changed upstream
- Any conflicts resolved

---

## Step 11 — Update Device

Only after Steps 1–10 pass:

1. Review the diff: `git diff custom/eric-main-old custom/eric-main` (if you kept the old reference)
2. Note any changes to VW-specific files or UI files
3. Confirm the testing ladder requirements in `docs/safety-boundaries.md`
4. Proceed to device update per `docs/device-install-and-rollback.md`

---

## Frequency

| Situation | Action |
|---|---|
| sunnypilot publishes a new release | Sync within 1–2 weeks |
| A specific upstream bug fix is needed | Sync immediately |
| Before a road trip | Do NOT sync — device stability is more important |
| Mid-development on a critical change | Do NOT sync — finish and push first |
| Recommended minimum cadence | Monthly |

---

## Emergency: Reset to Clean Upstream

If sync results in a broken state and you need to reset `custom/eric-main` to clean sunnypilot:

```bash
git checkout sunny-upstream
git branch -D custom/eric-main      # DESTRUCTIVE — ensure everything is pushed first
git checkout -b custom/eric-main sunny-upstream
git push --force-with-lease origin custom/eric-main:custom/eric-main
```

Then re-apply custom commits selectively:
```bash
git cherry-pick <commit-sha>
```
