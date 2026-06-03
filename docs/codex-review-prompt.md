# Codex Review & Audit Prompt
## TiguanSunnyPilot — Infrastructure, Documentation, and Shell Script Audit

---

## Context and Background

You are auditing the initial setup of a private personal fork of
[sunnypilot](https://github.com/sunnypilot/sunnypilot) — a safety-critical
automotive driver assistance system (ADAS) based on comma.ai's openpilot.

**This is vehicle control software. Safety is the highest priority.**

The fork owner is Eric Branan. The vehicle is a **2022 Volkswagen Tiguan SE**
(MQB platform, Generation MK2) running on a **Comma 3X** device.

The upstream project (sunnypilot) is at **v2026.001.000** as of June 2026.
This version is a major rewrite that replaced the Qt C++ UI with **Raylib Python**,
introduced the MADS (Modular Assistive Driving System) framework, and added Comma 4
support while retaining C3X support.

The setup was performed by an AI assistant and has **not yet been manually reviewed
by a human expert**. Your job is to find everything that is wrong, ambiguous,
incomplete, misleading, or risky.

---

## Repository Location

GitHub: `ericbranan/TiguanSunnyPilot` (private)

All source files are in this repository. The sunnypilot upstream code has NOT yet
been fetched — this repo currently contains only documentation and configuration.

---

## Complete File Inventory

```
.claude/hooks/session-start.sh    ← Shell hook that runs at every Claude Code session start
.claude/settings.json             ← Claude Code hook registration
.gitignore                        ← Files excluded from git
.markdownlint.json                ← Markdownlint rule config
CLAUDE.md                         ← Claude Code session context file
docs/change-log.md                ← Running change log template
docs/customization-map.md         ← Risk-rated customization areas
docs/device-install-and-rollback.md ← Device install/rollback guide
docs/eric-fork-overview.md        ← Fork purpose, remotes, branch strategy
docs/safety-boundaries.md         ← Non-negotiable safety rules
docs/sunnylink-notes.md           ← SunnyLink platform notes
docs/upstream-sync-workflow.md    ← Commands for pulling upstream updates
docs/volkswagen-tiguan-research.md ← VW Tiguan compatibility research
```

---

## Full File Contents

### `.claude/hooks/session-start.sh`

```bash
#!/bin/bash
set -euo pipefail

# Only run in remote Claude Code on the web sessions
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel 2>/dev/null || pwd)}"

# ── 1. markdownlint-cli (docs linting) ──────────────────────────────────────
if ! command -v markdownlint &>/dev/null; then
  npm install -g markdownlint-cli --silent
fi

# ── 2. Python tooling (pylint, black) ────────────────────────────────────────
if ! python3 -m pylint --version &>/dev/null 2>&1; then
  pip3 install --quiet --break-system-packages pylint black
fi

# ── 3. sunnypilot Python deps (only when source is present) ──────────────────
if [ -f "$PROJECT_DIR/pyproject.toml" ] && command -v uv &>/dev/null; then
  cd "$PROJECT_DIR"
  uv sync --quiet 2>/dev/null || true
elif [ -f "$PROJECT_DIR/requirements.txt" ]; then
  pip3 install --quiet --break-system-packages -r "$PROJECT_DIR/requirements.txt" 2>/dev/null || true
fi

# ── 4. Set PYTHONPATH when sunnypilot source is present ──────────────────────
if [ -f "$PROJECT_DIR/pyproject.toml" ] && [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PYTHONPATH=\"$PROJECT_DIR\"" >> "$CLAUDE_ENV_FILE"
fi
```

### `.claude/settings.json`

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

### `.gitignore`

```
# --- Secrets and credentials (never commit these) ---
*.pem
*.key
*.p12
*.pfx
id_rsa
id_ed25519
id_ecdsa
.env
.env.*
secrets.json
credentials.json
*.token

# --- Device identifiers (never commit these) ---
dongle_id
device_id
*.dongle
params_backup*/

# --- Python ---
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
*.egg-info/
dist/
build/
.venv/
venv/
env/

# --- IDE and editor ---
.vscode/settings.json
.idea/
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# --- Build artifacts ---
*.o
*.so
*.a
*.out
*.bin
*.elf
*.map
cereal/gen/
*.capnp.h

# --- Log files ---
*.log
*.log.*
selfdrive/debug/

# --- Calibration data (device-specific, not for repo) ---
liveCalibration.json
LiveCalibration/

# --- Notes and scratch files ---
scratch/
notes/
TODO.md
```

### `.markdownlint.json`

```json
{
  "default": true,
  "MD013": false,
  "MD022": false,
  "MD031": false,
  "MD032": false,
  "MD034": false,
  "MD040": false,
  "MD060": false
}
```

### `CLAUDE.md` (abbreviated — key sections)

- Describes vehicle (2022 VW Tiguan SE, MQB), hardware (Comma 3X), upstream
  (sunnypilot v2026.001.000+, master branch)
- Remotes: `upstream` = sunnypilot/sunnypilot (push DISABLED), `origin` = ericbranan/TiguanSunnyPilot
- Branches: `sunny-upstream`, `custom/tiguan-ui`, `custom/tiguan-params`, `custom/eric-main`
- Safety rules listed (never modify panda/, MPC solvers, DBC files, driver monitoring,
  fingerprints, push to upstream, commit secrets)
- Acceptable: UI text/colors/layouts, default param values, audio assets, Tiguan param preferences
- Links to all docs files

### `docs/eric-fork-overview.md` (abbreviated)

- Branch strategy table: `sunny-upstream` / `custom/tiguan-ui` / `custom/tiguan-params` /
  `custom/eric-main`
- Rules: sunny-upstream never gets custom commits; custom branches rebase onto it
- Fork install URL: `install.sunnypilot.ai/fork/USERNAME/BRANCH` (public forks only)
- C3X stable URL: `release.sunnypilot.ai`; dev URL: `dev.sunnypilot.ai`
- Status table shows "Branch structure created — documented, initial commit pending" (outdated)
- Notes private fork requires SSH for device installation

### `docs/upstream-sync-workflow.md` (abbreviated)

Key commands documented:
```bash
git fetch upstream --no-tags
git checkout sunny-upstream
git merge --ff-only upstream/master
git checkout custom/tiguan-ui && git rebase sunny-upstream
git checkout custom/tiguan-params && git rebase sunny-upstream
git checkout custom/eric-main
git rebase sunny-upstream
git merge --no-ff custom/tiguan-ui -m "merge: tiguan-ui after upstream sync"
git merge --no-ff custom/tiguan-params -m "merge: tiguan-params after upstream sync"
git push origin sunny-upstream custom/tiguan-ui custom/tiguan-params custom/eric-main
```

Also includes: secrets scan via grep, pylint on VW car files, py_compile check

### `docs/device-install-and-rollback.md` (abbreviated)

- **Option A** (public fork): URL `install.sunnypilot.ai/fork/ericbranan/custom-eric-main`
- **Option B** (private fork, SSH):
  ```bash
  cd /data
  mv openpilot openpilot.bak_$(date +%Y%m%d)
  git clone --depth=1 -b custom/eric-main https://github.com/ericbranan/TiguanSunnyPilot.git openpilot
  cd openpilot
  git submodule update --init --recursive
  sudo reboot
  ```
- Device update via SSH (for subsequent updates):
  ```bash
  cd /data/openpilot
  git fetch origin
  git checkout custom/eric-main
  git pull origin custom/eric-main
  git submodule update --recursive
  sudo reboot
  ```
- Rollback Method 1 (device still boots): enter `dev.sunnypilot.ai` via Settings → Software
- Rollback Method 2 (SSH, broken UI):
  ```bash
  rm -rf openpilot
  git clone --depth=1 -b __nightly https://github.com/sunnypilot/sunnypilot.git openpilot
  ```
- Backup: `cp -r /data/openpilot openpilot.bak_$(date +%Y%m%d_%H%M)`
- Record state: `cat /data/params/d/GitCommit`, `cat /data/params/d/GitBranch`

### `docs/sunnylink-notes.md` (abbreviated)

- SunnyLink can: settings sync, model switching, device monitoring, backup/restore
- SunnyLink cannot: install custom forks, access private repos, SSH/shell access,
  force reboots, flash firmware
- SunnyLink integration code lives at `/sunnypilot/sunnylink/` — do not modify
- After installing custom fork, re-pair SunnyLink (generate new pairing code on device)

### `docs/volkswagen-tiguan-research.md` (abbreviated)

- VW Tiguan MK2 (2018-24), MQB, J533 harness, platform: `VolkswagenMQBPlatformConfig`
- Mass: 1715 kg, wheelbase: 2.74m, steer ratio: 15.6
- Code files: `opendbc_repo/opendbc/car/volkswagen/` (values, carstate, carcontroller,
  fingerprints, interface), DBC: `opendbc/dbc/vw_mqb_2010.dbc`
- panda safety: `panda/board/safety/safety_volkswagen.h` — hardware-enforced
- Longitudinal: stock ACC only by default; openpilot longitudinal is experimental/unsupported
- J533 intercepts extended CAN bus (HCA/LKAS + ACC setpoints)
- ACC High (stop-and-go + auto-resume) vs ACC Low (driver must resume) — type not confirmed for 2022 SE
- 2022 harness concern: may have combined gateway/BCM — physical verification recommended
- Open questions: ACC type, gateway vs BCM, firmware version, sunnypilot community quirks

### `docs/customization-map.md` (abbreviated)

Five categories:
1. Safe UI/Visual (LOW risk) — HUD, alerts, assets, settings labels
2. sunnypilot Settings & Params (LOW) — defaults, speed limits, lane mode, sounds, model
3. VW-Specific Behavior (LOW-MEDIUM) — ACC gap, LKAS mode, longitudinal toggles, button mapping
4. Vehicle Interface Code (HIGH) — carstate, carcontroller, platform config, fingerprints
5. Safety Critical / Do Not Touch (CRITICAL) — panda, MPC solvers, DBC, locationd, sensord,
   SConstruct, launch scripts, calibration

Note about v2026 UI rewrite: Qt → Raylib Python; old Qt patches invalid

### `docs/safety-boundaries.md` (abbreviated)

Hard rules:
- panda safety is inviolable
- Steering torque limits cannot be exceeded (hardware-enforced)
- Driver monitoring cannot be disabled
- Longitudinal: stock ACC only; openpilot longitudinal requires explicit validation
- No safety feature removal

Testing ladder: Code Review → Static Device Test → Static Vehicle Test (ignition on,
no engage) → Slow-speed controlled environment (≤15 mph, parking lot, spotter) → Normal road

### `docs/change-log.md`

Template only — one entry for initial setup (2026-06-03).

---

## Git Configuration Applied

```
remote.pushDefault = origin
push.default = current
upstream push URL = DISABLED (literal string)
```

Branch structure pushed to origin:
- `claude/practical-gates-T1eE1` (working branch for this setup)
- `sunny-upstream`
- `custom/tiguan-ui`
- `custom/tiguan-params`
- `custom/eric-main`

All branches currently point to the same initial commit (35e3d25).

---

## Sunnypilot Architecture Facts (for reference during review)

You may use your knowledge of sunnypilot, openpilot, and comma.ai devices to
cross-check the documentation. Key verified facts:

- sunnypilot v2026.001.000 (May 2026) replaced the Qt C++ UI with **Raylib Python**
- The car database (fingerprints, values, car interface) is in the **opendbc submodule**
  at `opendbc_repo/`, not in the main repo's `selfdrive/car/`
- panda firmware is a separate submodule (`panda/`) with its own build system
- sunnypilot-specific features live in the `sunnypilot/` top-level directory
- The device OS is **AGNOS** (Linux-based); Comma 3X runs on Qualcomm hardware
- The Comma 3X is referred to internally as "tizi" (hence branch suffix `-tizi`)
- `dev.sunnypilot.ai` and `release.sunnypilot.ai` serve AGNOS installer scripts;
  they respond 403 to normal HTTP clients but serve the correct binary to device user-agents
- `install.sunnypilot.ai/fork/username/branch` is a sunnypilot-hosted installer for
  **public** GitHub forks only — no authentication support
- SunnyLink frontend is open-source at `github.com/sunnypilot/sunnylink-frontend`
- The VW Tiguan MK2 entry in opendbc uses `VOLKSWAGEN_TIGUAN_MK2` (chassis 5N/AD/AX/BW)
- opendbc path for VW: `opendbc_repo/opendbc/car/volkswagen/`
- DBC file for MQB: `opendbc_repo/opendbc/dbc/vw_mqb_2010.dbc`
- panda VW safety: `panda/board/safety/safety_volkswagen.h`
- sunnypilot `__nightly` branch exists and is a valid rollback target

---

## Your Audit Tasks

Perform a complete review across every category below. For each finding, specify:
- **File and line/section** where the issue appears
- **Issue type**: Bug | Error | Inconsistency | Missing | Outdated | Risk | Unclear
- **Severity**: Critical | High | Medium | Low | Informational
- **Exact problem description**
- **Recommended fix** (specific, actionable)

---

### TASK 1 — Shell Script Audit (`session-start.sh`)

Review the session-start hook for correctness, robustness, idempotency, and edge cases.

Specific things to check:

1.1 **PROJECT_DIR resolution**: The line
    ```bash
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel 2>/dev/null || pwd)}"
    ```
    — Is the relative path `"$(dirname "$0")/../.."` correct for resolving the project
    root from `.claude/hooks/session-start.sh`? Trace the directory math.
    `.claude/hooks/` is 2 levels deep, so `/../..` from the script location should
    resolve to the repo root. Verify whether `dirname "$0"` returns an absolute or
    relative path, and whether this is safe when the script is called with different
    working directories (e.g., from the repo root, from a subdirectory, or from `/`).

1.2 **`set -euo pipefail` + `|| true` interaction**: Several commands use `|| true`
    or `2>/dev/null || true` to suppress failures. With `set -e` active, are there
    scenarios where a failure inside a subshell or command substitution could cause
    the script to exit unexpectedly before reaching those suppressors? Specifically
    check the `uv sync` and `pip install` paths.

1.3 **`pip3 install --break-system-packages`**: On some Debian/Ubuntu systems this
    flag causes pip to install into the system Python, which can conflict with
    system packages. Is there a safer approach? Should a virtual environment be
    used instead, and if so how would that interact with `CLAUDE_ENV_FILE`?

1.4 **npm install race condition**: `npm install -g markdownlint-cli --silent` —
    is the `--silent` flag correct for suppressing output in npm v9+? Does it
    suppress errors too? Is there a `--quiet` flag that is more appropriate?

1.5 **Idempotency of `CLAUDE_ENV_FILE` write**: The script appends
    `export PYTHONPATH="$PROJECT_DIR"` to `$CLAUDE_ENV_FILE` every time a session
    starts when `pyproject.toml` is present. If the session is resumed multiple
    times, does this result in duplicate `PYTHONPATH` entries? What is the effect
    of multiple `export PYTHONPATH=...` lines in the env file?

1.6 **Missing: `uv` path**: `uv` was confirmed at `/root/.local/bin/uv` in the
    environment. Is `/root/.local/bin` reliably in `PATH` in all remote session
    contexts? Should the script check the full path or add it to PATH explicitly?

1.7 **Missing: submodule initialization check**: When sunnypilot source is present,
    submodules (`panda`, `opendbc_repo`, etc.) must be initialized. Is there any
    check or step for this? Should the hook also run
    `git submodule update --init --recursive` when source is detected?

1.8 **Exit code behavior**: If `npm install -g markdownlint-cli` fails (e.g., no
    internet), `set -e` will cause the entire hook to exit non-zero. Will a failed
    hook block the Claude Code session from starting? Should tool installation
    failures be made non-fatal with `|| true`?

1.9 **Missing: `git` availability check**: The `PROJECT_DIR` fallback uses
    `git rev-parse`. What happens if git is not installed or the directory is not a
    git repository? Is the `|| pwd` fallback safe and correct?

1.10 **pylint/black check**: The idempotency check
     `python3 -m pylint --version &>/dev/null 2>&1` — the `&>/dev/null 2>&1` is
     redundant (both stdout and stderr are already redirected by `&>`). Is this
     harmless or does it indicate a deeper misunderstanding? Also: should `black` be
     checked separately for idempotency rather than assuming it installs with pylint?

---

### TASK 2 — Git Configuration Audit

2.1 **`push.default = current`**: With `push.default = current`, running
    `git push` on `sunny-upstream` (which has no custom tracking) will push to
    a remote branch of the same name on `origin`. Is this the safest default for
    a fork that must never push to upstream? Compare with `push.default = nothing`
    which requires explicit remote:branch specification. Document the trade-off.

2.2 **Upstream push protection**: The upstream push URL is set to the literal string
    `DISABLED`. Verify: if a user runs `git push upstream master`, does git reject
    this with a clear error, or does it attempt to connect to a host named DISABLED?
    What exact error message appears? Is this protection sufficient, or should
    `git remote set-url upstream <readonly-url>` plus `push = DISABLED` be
    supplemented with a pre-push hook?

2.3 **`remote.pushDefault = origin`**: This config key — confirm whether it is
    `remote.pushDefault` or `branch.*.remote`. Does `remote.pushDefault` actually
    exist as a valid git config option, or is the correct key `push.default`? Verify
    against `git config --list` expected output.

2.4 **Branch tracking**: All custom branches (`custom/tiguan-ui`, `custom/tiguan-params`,
    `custom/eric-main`, `sunny-upstream`) are at the same initial commit and track
    their origin counterparts. When `sunny-upstream` is later fast-forwarded to
    `upstream/master`, will `git push origin sunny-upstream` correctly push to
    `origin/sunny-upstream`? Trace the full push path.

2.5 **Missing: pre-push hook**: There is no pre-push hook to prevent accidental pushes
    to `upstream`. Should there be one? Draft the minimal pre-push hook that would
    reject any push whose remote URL matches `github.com/sunnypilot`.

2.6 **Branch naming with slashes**: Branches named `custom/tiguan-ui` use forward
    slashes. On some git clients (especially Windows) and some git hosting platforms,
    slash-separated branch names can cause issues (e.g., treated as directories).
    Flag this as a low-risk note for cross-platform usage.

2.7 **`--no-tags` in fetch**: Step 2 of the sync workflow uses `git fetch upstream --no-tags`.
    sunnypilot uses tags for releases (e.g., `v2026.001.000`). By excluding tags from
    the fetch, `git log` will not show release tag annotations when comparing branches.
    Is this intentional? Should tags be fetched with `--tags` from upstream to make
    release comparison easier?

---

### TASK 3 — Documentation Accuracy and Completeness

3.1 **Outdated status table** (`eric-fork-overview.md` §8): The status table says
    "Branch structure created — documented, initial commit pending." The initial
    commit has already been made (35e3d25). This table is already stale.
    Flag all other outdated items in the status table.

3.2 **Install URL inconsistency**: `eric-fork-overview.md` §2 shows the fork install
    URL as `install.sunnypilot.ai/fork/USERNAME/BRANCH`, but the upstream repo
    section shows C3X stable as `release.sunnypilot.ai` (no protocol). The device
    install doc (`device-install-and-rollback.md` §2A) shows:
    `install.sunnypilot.ai/fork/ericbranan/custom-eric-main`.
    — The branch name in Option A uses a forward slash in the branch name
    (`custom/eric-main`). Verify: does `install.sunnypilot.ai/fork/` handle
    branch names with slashes? The URL would be
    `install.sunnypilot.ai/fork/ericbranan/custom/eric-main` — is the branch
    segment parsed correctly, or does the slash break the URL path parsing?

3.3 **Rollback target `__nightly`**: `device-install-and-rollback.md` Method 2
    uses `git clone --depth=1 -b __nightly https://github.com/sunnypilot/sunnypilot.git`.
    The `__nightly` branch was observed in the sunnypilot branches list. However:
    — Is `__nightly` a source branch or a prebuilt branch? Prebuilt branches on
    sunnypilot are typically built from the source and include compiled binaries
    for the device. Cloning the `__nightly` branch into `/data/openpilot` on
    device may or may not be the correct approach depending on how sunnypilot
    structures its prebuilt branches. Investigate and document whether this is
    a source branch (requires build steps) or a ready-to-run prebuilt.

3.4 **Submodule initialization in device install**: Option B SSH install includes:
    ```bash
    git submodule update --init --recursive
    ```
    However, sunnypilot has many large submodules (`tinygrad`, `opendbc`, `panda`,
    `rednose`, etc.). On a Comma 3X with limited storage and network bandwidth,
    `--recursive` may pull hundreds of megabytes of data. Does the device have enough
    storage? Is `--depth=1` needed on the submodule clone as well? The `--depth=1`
    on the main clone does not propagate to submodules by default in older git
    versions. Should the command be:
    ```bash
    git submodule update --init --recursive --depth=1
    ```
    Note: `--depth` for submodule update requires git 2.10+. Document the correct
    version-appropriate command.

3.5 **Missing: AGNOS version / software compatibility note**: sunnypilot requires
    a specific AGNOS version on the Comma 3X. A custom fork must be based on a
    compatible AGNOS version. If the fork diverges too far from upstream, AGNOS
    API changes could break it. This constraint is not mentioned anywhere in
    the documentation. Add a note.

3.6 **VW research: ACC type determination**: `volkswagen-tiguan-research.md` §9
    notes that ACC type (High vs Low) for the 2022 Tiguan SE is unknown. This is
    a critical open question — ACC Low means the vehicle will not auto-resume after
    a complete stop, changing the fundamental driving experience. The document
    correctly flags this but does not provide a method to determine it. Add the
    actual method: check the vehicle's original documentation or look for the
    "Traffic Jam Assist" or "Follow to Stop" feature in the options list. Also:
    the ACC type can potentially be determined by checking the VW gateway module
    coding via OBD2.

3.7 **VW research: fingerprint path is incorrect**: The document references
    `opendbc_repo/opendbc/car/volkswagen/fingerprints.py`, but in the current
    sunnypilot/opendbc architecture, fingerprints are stored in `values.py` as
    part of the `CarDocs` and `CAR` class definitions, not in a separate
    `fingerprints.py`. Verify the actual file structure in opendbc and correct
    this reference if wrong.

3.8 **VW research: openpilot longitudinal for MQB**: The document states
    "openpilot longitudinal is experimental/unsupported." However, sunnypilot
    specifically advertises "Custom Stock Longitudinal Control" for VW MQB.
    This is different from "openpilot longitudinal" — it uses the stock ACC
    system but with sunnypilot controlling the setpoint more aggressively.
    The distinction is important and the document conflates the two. Clarify:
    - **Stock longitudinal**: Factory ACC, openpilot only adjusts the setpoint
    - **Custom Stock Longitudinal (sunnypilot)**: Modified setpoint algorithm,
      still uses factory ACC, available for VW MQB in sunnypilot
    - **openpilot longitudinal**: OP directly controls braking via CAN —
      NOT supported for VW MQB in stock openpilot

3.9 **Missing: opendbc submodule version pinning**: When the full upstream sync is
    done, the `opendbc_repo` submodule will be pinned to a specific commit.
    The sync workflow documentation does not mention checking or updating this
    submodule pin. After `git merge --ff-only upstream/master`, the submodule
    pointer in the main repo will point to the upstream-pinned opendbc commit.
    The custom branches need to be aware that rebasing might update the submodule
    pointer. This is not covered in the sync workflow. Document it.

3.10 **Customization map: UI file paths are speculative**: The map cites
     `selfdrive/ui/` (Qt) and `sunnypilot/selfdrive/ui/` (Raylib) as UI locations.
     Since sunnypilot v2026 completely rewrote the UI in Raylib Python, the exact
     paths are unknown without inspecting the actual branch. The document correctly
     notes this uncertainty, but it should be MORE prominent — it should say
     explicitly: "Do not write any UI customization code until you have fetched
     the upstream branch and verified the actual file paths." The current wording
     buries this warning.

3.11 **Missing: gitconfig for submodule handling**: The sync workflow does not
     address submodule status after rebase. After `git rebase sunny-upstream`,
     if the upstream changed the opendbc submodule pointer, the rebase may
     produce conflicts in `.gitmodules` or the submodule directory entry.
     Add a step to check submodule status:
     ```bash
     git submodule status
     ```
     And guidance on resolving submodule pointer conflicts.

3.12 **Missing: what happens after `git rebase` on `custom/eric-main`**: The
     workflow says to rebase `custom/eric-main` onto `sunny-upstream` and THEN
     merge the feature branches. But if `custom/eric-main` was previously built
     by merging `custom/tiguan-ui` and `custom/tiguan-params`, the rebase will
     replay all those merge commits too. This is typically wrong — the correct
     pattern is to delete and recreate `custom/eric-main` after each upstream sync,
     not rebase it. Document the correct pattern:
     ```bash
     git checkout sunny-upstream
     git checkout -b custom/eric-main-new
     git merge --no-ff custom/tiguan-ui
     git merge --no-ff custom/tiguan-params
     git branch -m custom/eric-main custom/eric-main-old
     git branch -m custom/eric-main-new custom/eric-main
     git branch -D custom/eric-main-old  # after verifying
     git push --force-with-lease origin custom/eric-main
     ```
     This is the standard "integration branch" pattern and avoids the rebasing
     of merge commits problem.

3.13 **`.gitignore` gaps for sunnypilot**: When the sunnypilot source is added,
     the following sunnypilot-specific files/patterns should also be excluded:
     - `selfdrive/debug/*.log`
     - `*.pyc` (already covered)
     - `selfdrive/car/tests/test_models_output/`
     - `.hypothesis/` (test framework state)
     - `third_party/` — may contain compiled binaries that shouldn't be re-committed
     - `tinygrad_repo/` compiled artifacts (if present)
     - `/.venv/` (virtual env at project root, used by uv)
     - `uv.lock` — should this be committed or excluded? (Typically: commit it for
       reproducibility. Flag this as a decision point.)

---

### TASK 4 — Safety Boundary Review

4.1 **Testing ladder gap**: The testing ladder in `safety-boundaries.md` moves from
    "Slow-speed controlled environment (≤15 mph)" directly to "Normal road use."
    This is an unrealistic jump. There should be an intermediate stage for
    low-speed residential road driving (≤25 mph) with explicit criteria for
    what must pass before moving to highway speeds. Add this stage.

4.2 **Missing: what to do if panda rejects a command**: The documentation explains
    that panda enforces safety limits in hardware, but does not explain what the
    driver experiences when panda blocks a command (e.g., the ADAS disengages with
    an alert). Add a note so users understand this is expected behavior, not a bug.

4.3 **`custom/tiguan-params` risk level inconsistency**: The overview doc says this
    branch is "low-medium risk" and the customization map puts parameter changes
    at "LOW" risk. These are inconsistent. Reconcile.

4.4 **Missing: DBC change impact scope**: The safety doc says "Do not modify DBC files
    without upstream review" but does not explain WHY. Add a clear explanation:
    DBC files define the parsing of ALL CAN messages across ALL vehicles using that
    bus — an incorrect bit offset or scaling factor corrupts every signal decoded
    from that message, potentially causing the wrong speed, steering angle, or
    braking state to be reported, with no error indication.

4.5 **Missing: explicit guidance for contributing upstream**: If the user discovers
    a genuine bug in the VW interface code (e.g., a wrong fingerprint for a new
    firmware version), the safety doc has no guidance on how to contribute it
    upstream safely rather than keeping it as a private fork change. Add this.

---

### TASK 5 — Cross-Document Consistency

5.1 Check that the branch name `custom/eric-main` is used consistently everywhere.
    Flag any places where a different name is used (e.g., `eric-main` without
    the `custom/` prefix).

5.2 Check that the upstream URL `https://github.com/sunnypilot/sunnypilot.git` is
    consistent everywhere. Flag any references to the old `sunnyhaibin/sunnypilot`
    repository (sunnypilot moved from `sunnyhaibin` to the `sunnypilot` organization).

5.3 The device install doc says the rollback branch is `__nightly`, while the
    overview doc says the current install is `dev.sunnypilot.ai`. Clarify: is
    `dev.sunnypilot.ai` the same as `__nightly`, or are they different branches?
    The `dev.sunnypilot.ai` URL serves an AGNOS installer script, while `__nightly`
    appears to be a git branch. These may not be equivalent. Document the difference.

5.4 The CLAUDE.md quick reference says:
    ```bash
    git push upstream <anything>   # push URL is disabled, but don't attempt it
    ```
    This is a comment telling Claude NOT to run it, but it's formatted as a code
    block which could be mistakenly executed. Rephrase to be unambiguous.

5.5 The `eric-fork-overview.md` §3 shows the origin URL without `.git` suffix:
    `https://github.com/ericbranan/TiguanSunnyPilot`
    but the actual remote URL configured in git ends with `.git`. This is a minor
    inconsistency — git handles both, but the documentation should be consistent.

---

### TASK 6 — Missing Operational Procedures

6.1 **No procedure for checking device SSH reachability before use**: Multiple docs
    reference SSHing to the device, but there is no documented procedure for
    finding the device IP address (the Comma 3X shows its IP in Settings → Network,
    or it can be found via the router's DHCP table). Add this.

6.2 **No procedure for initial SunnyLink pairing**: The user is already signed into
    SunnyLink, but the docs don't describe the initial pairing procedure for a
    freshly installed fork. Add the steps: device generates pairing code →
    enter it in SunnyLink dashboard.

6.3 **No versioning strategy for custom changes**: The change-log template exists,
    but there is no guidance on how to version the fork itself (e.g., should it
    use the same version string as upstream + a suffix, or a completely different
    version?). Add a recommendation.

6.4 **Missing: how to view drive logs for debugging**: After a problematic drive,
    how does the user retrieve logs? This is important for diagnosing any issues
    with the custom fork. Add: routes/logs are stored at `/data/media/0/realdata/`
    on the device and can be accessed via SSH or viewed through SunnyLink.

---

### TASK 7 — Security Review

7.1 **`.gitignore` covers `id_rsa` and `id_ed25519` but not `id_dsa` or `id_ecdsa`
    in all variants**: Also missing are `*.pub` (public keys should not be committed
    either — they reveal key fingerprints), `authorized_keys`, and
    `known_hosts`. Add these.

7.2 **Secrets scan command in sync workflow**: The grep pattern is:
    ```bash
    git diff HEAD | grep -iE "(token|secret|password|api_key|private_key)" | head -20
    ```
    This only scans staged/committed changes since HEAD, not the entire working tree
    or all commits. It also won't catch common secret patterns like AWS keys
    (`AKIA...`), GitHub PATs (`ghp_...`), or base64-encoded credentials.
    Recommend using `git-secrets`, `trufflehog`, or `gitleaks` instead, and add
    a note about scanning the full repo history after the initial upstream sync.

7.3 **`--break-system-packages` security consideration**: On a production system,
    this flag could silently downgrade or replace system-managed Python packages.
    The environment here is an ephemeral container so this is acceptable, but add
    a comment in the script explaining why this flag is safe in this context and
    should not be used on a non-ephemeral system.

7.4 **Deploy key guidance is missing**: `device-install-and-rollback.md` mentions
    using an SSH deploy key for private repo installation but gives no step-by-step
    instructions. Add: how to generate a deploy key, add it to the GitHub repo's
    deploy keys (read-only), and place it on the Comma 3X so the device can clone
    the private fork without exposing the user's full GitHub SSH key.

---

## Output Format

For each finding, use this exact format:

```
### [SEVERITY] [TYPE] — [Short title]

**File:** `path/to/file.ext` (line N or section name)
**Problem:** Clear description of the issue.
**Fix:** Specific, actionable recommendation. Include corrected code/text where applicable.
```

Group findings by Task number. At the end, provide:
- A summary table of all findings by severity
- A prioritized action list (what to fix first before the first device install)
- Anything that is specifically correct and well-done (don't only report problems)

---

## Audit Scope Boundaries

**In scope:**
- All files listed above
- Cross-document consistency
- Shell script correctness and safety
- Git workflow correctness
- Documentation accuracy against known sunnypilot/openpilot architecture
- Security considerations for a private vehicle software fork

**Out of scope:**
- The full sunnypilot codebase (not yet in this repo)
- opendbc internals beyond what is documented above
- AGNOS OS internals
- Comma hardware specifications beyond what is documented above
- Legal / licensing analysis
- Network security of the comma.ai infrastructure
