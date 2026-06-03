# Change Log

This log records all significant changes made to the `ericbranan/TiguanSunnyPilot` fork.

---

## Fork Versioning Convention

Each device install is identified by:

```
<upstream-version>-eric.<fork-revision>
```

Example: `2026.001.000-eric.1`

Where:
- `2026.001.000` = sunnypilot upstream version at the time of the sync
- `eric.1` = fork revision counter (increment for each device install of a given upstream base)

Record the following for every device install in the "Device Install History" table:

| Field | Example |
|---|---|
| Date | 2026-06-15 |
| Fork version | 2026.001.000-eric.1 |
| Upstream commit | `abc1234` (from `git rev-parse upstream/master`) |
| Fork commit | `def5678` (from `git rev-parse custom/eric-main`) |
| opendbc submodule SHA | `ghi9012` (from `git submodule status opendbc_repo`) |
| panda submodule SHA | `jkl3456` (from `git submodule status panda`) |
| AGNOS version | `10.2.1` (from `/VERSION` on device) |

Store this table in a local file (e.g., `~/tiguan-installs.txt`). Do NOT commit it to the
repo if it contains device-specific identifiers.

---

## Change Entry Format

| Field | Description |
|---|---|
| Date | YYYY-MM-DD |
| Branch | Which branch was modified |
| Commit | Short SHA or "pending" |
| Change | What was changed |
| Reason | Why it was changed |
| Risk | LOW / MEDIUM / HIGH / CRITICAL |
| Test | What testing was performed |
| Rollback | How to undo if needed |

---

## Log

| Date | Branch | Commit | Change | Reason | Risk | Test | Rollback |
|---|---|---|---|---|---|---|---|
| 2026-06-03 | `claude/practical-gates-T1eE1` | `35e3d25` | Created repository, added upstream remote, wrote initial documentation | Fork setup | LOW | Git remote and branch verification | `git reset HEAD~N` on initial commits |
| 2026-06-03 | `claude/practical-gates-T1eE1` | `c3774f4` | Added session-start hook, .claude/settings.json, .markdownlint.json | CI/tooling setup | LOW | Hook ran clean (exit 0), markdownlint passes | Remove .claude/hooks/session-start.sh |
| 2026-06-03 | `claude/practical-gates-T1eE1` | `1c3ad9c` | Added Codex review prompt | Documentation | LOW | Markdownlint clean | `git revert 1c3ad9c` |
| 2026-06-03 | `claude/practical-gates-T1eE1` | (this commit) | Applied all 45 findings from Codex audit: hook bugs, git safety, docs accuracy, .gitignore, pre-push hook, setup script | Audit remediation | LOW | All docs lint clean; hook validated | `git revert` individual commits |

---

## Upstream Sync History

| Date | Upstream Commit | Previous Upstream Commit | opendbc SHA | panda SHA | Conflicts | Notes |
|---|---|---|---|---|---|---|
| 2026-06-03 | (not yet fetched) | N/A | N/A | N/A | N/A | Initial setup only — upstream remote added but not fetched |

---

## Notes

- Always add an entry before pushing any change to `custom/eric-main`
- Include the actual commit SHA once committed
- "Test" describes what was actually done, not planned
- Risk level reflects actual risk, not hoped-for outcome
