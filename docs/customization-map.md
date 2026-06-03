# Customization Map

This document maps potential customization areas in the sunnypilot codebase,
categorized by risk level and specific to the `ericbranan/TiguanSunnyPilot` fork.

**Risk scale:**
- `LOW` — cosmetic or param change; safe to experiment
- `MEDIUM` — behavioral but bounded; test carefully before driving
- `HIGH` — affects core driving logic; do not change without deep code review
- `CRITICAL` — safety boundaries; off-limits in this fork

---

## Category 1 — Safe UI / Visual Changes

| Area | Files / Directories | Purpose | Risk | Merge Conflict Likelihood | Test Method | Rollback |
|---|---|---|---|---|---|---|
| Onroad HUD layout | `selfdrive/ui/` (Qt) or `sunnypilot/selfdrive/ui/` (Raylib, v2026+) | What's shown on screen during driving | LOW | MEDIUM (UI changes frequently upstream) | Visual inspection on parked device | `git revert` the commit |
| Alert text and messages | `selfdrive/ui/alerts.py` or similar | Driver alert wording | LOW | LOW | Read alerts on screen | `git revert` |
| App icon and splash assets | `selfdrive/assets/` | Boot screen, icons | LOW | LOW | Boot device | `git revert` |
| Settings UI labels | `selfdrive/ui/settings/` | Settings menu text | LOW | MEDIUM | Navigate settings | `git revert` |
| Custom onroad info box | `selfdrive/ui/` or `sunnypilot/selfdrive/` | Speed, gear, nav info overlays | LOW | MEDIUM | Drive slowly in parking lot | `git revert` |

**Note on UI (v2026+ change):** As of sunnypilot v2026.001.000, the UI was completely
rewritten from Qt C++ to Raylib Python. This is a major change. All UI customizations must
target the new Raylib Python codebase, not the old Qt code. Targeting the wrong layer will
produce patches that do not apply.

Look for Python files in `sunnypilot/selfdrive/` or a dedicated UI directory in the
sunnypilot-specific path.

---

## Category 2 — sunnypilot Settings and Parameter Defaults

| Area | Files / Directories | Purpose | Risk | Merge Conflict | Test Method | Rollback |
|---|---|---|---|---|---|---|
| Default toggle values | `selfdrive/car/interfaces.py`, param init files | What toggles are on/off by default | LOW | LOW | Check settings screen | `git revert` |
| Speed limit source priority | params, `sunnypilot/selfdrive/` | Which speed limit source is preferred | LOW | LOW | Drive on known speed-limited road | `git revert` |
| Lane mode defaults | params | Default lane centering mode | LOW | LOW | Drive, observe behavior | `git revert` |
| Alert sound profiles | `selfdrive/assets/sounds/` | Audio assets | LOW | LOW | Listen during drive | `git revert` |
| Driving model default | `sunnypilot/selfdrive/` | Which NN model to use by default | MEDIUM | LOW | Parking lot test | `git revert` |

---

## Category 3 — Volkswagen-Specific Behavior Settings

| Area | Files / Directories | Purpose | Risk | Merge Conflict | Test Method | Rollback |
|---|---|---|---|---|---|---|
| Tiguan default ACC gap | params / platform config | Following distance preference | LOW | LOW | Drive behind a vehicle | `git revert` |
| Lane assist mode for VW | VW platform params | Whether LKAS is on by default | LOW | LOW | Drive in marked lane | `git revert` |
| Custom longitudinal toggles for MQB | sunnypilot VW-specific toggles | Custom stock longitudinal behavior | MEDIUM | MEDIUM | Controlled road test | `git revert` |
| VW button mapping | `opendbc_repo/.../carstate.py` | Which stalk buttons do what | MEDIUM | LOW | Test buttons on parked car | `git revert` |

**Note:** VW-specific param changes should be verified against what the sunnypilot docs
say for VW MQB. Not all params apply to all vehicles.

---

## Category 4 — Vehicle Interface Code

| Area | Files / Directories | Purpose | Risk | Merge Conflict | Test Method | Rollback |
|---|---|---|---|---|---|---|
| Car state reader | `opendbc_repo/opendbc/car/volkswagen/carstate.py` | Parses CAN → car state | HIGH | LOW | CAN data logging, observe dashcam | `git revert` + verify fingerprint still works |
| Car controller | `opendbc_repo/opendbc/car/volkswagen/carcontroller.py` | Sends CAN commands | HIGH | LOW | Static/parked test with monitoring | `git revert` immediately |
| Platform config / specs | `opendbc_repo/opendbc/car/volkswagen/values.py` | Physical vehicle specs used in control | HIGH | LOW | Drive with telemetry monitoring | `git revert` |
| Fingerprint data | `opendbc_repo/opendbc/car/volkswagen/fingerprints.py` | Vehicle identification | HIGH | LOW | Boot device in car | `git revert` |

**WARNING:** Changes to vehicle interface code in `opendbc_repo` affect ALL vehicles
using that code path, not just the Tiguan. This fork should not modify opendbc vehicle
interface code unless adding a new fingerprint entry for a specific firmware variant,
and only after thorough documentation and upstream PR submission.

---

## Category 5 — Safety-Critical Code

| Area | Files / Directories | Purpose | Risk | Merge Conflict | Test Method | Rollback |
|---|---|---|---|---|---|---|
| panda safety | `panda/board/safety/safety_volkswagen.h` | Hardware-enforced steering/braking limits | CRITICAL | N/A | N/A | N/A |
| panda firmware | `panda/board/` | CAN relay firmware | CRITICAL | N/A | N/A | N/A |
| openpilot safety model | `selfdrive/controls/lib/` | Software safety limits | CRITICAL | N/A | N/A | N/A |
| Driver monitoring | `selfdrive/monitoring/` | Driver attentiveness detection | CRITICAL | N/A | N/A | N/A |
| Watchdog / process monitor | `system/manager/` | Ensures processes are running correctly | CRITICAL | N/A | N/A | N/A |

---

## Category 6 — Do Not Touch Without Expert Review

The following areas must not be modified in this fork under any circumstances:

| Area | Reason |
|---|---|
| `panda/` (any file) | Hardware safety enforcement — changes require panda reflash and extensive testing |
| `selfdrive/controls/lib/longitudinal_mpc*` | MPC solver for braking/accel — subtle bugs cause dangerous behavior |
| `selfdrive/controls/lib/lateral_mpc*` | MPC solver for steering — same concern |
| `opendbc/dbc/*.dbc` | CAN message definitions — wrong values can corrupt ALL vehicle signals |
| `selfdrive/locationd/` | Localization and sensor fusion — affects route planning and safety |
| `selfdrive/sensord/` | IMU and sensor drivers — affects safety-critical sensor fusion |
| `SConstruct` build system | Build order changes can produce incorrect binaries |
| `launch_*.sh` scripts | Boot sequence — breaking this bricks the device |
| Calibration parameters | Stored in device params — should be auto-calibrated, not manually set |

---

## Notes on the v2026.001.000 Architecture Change

sunnypilot v2026.001.000 (May 2026) is a major rewrite. Key changes that affect
customization:

1. **UI rebuilt in Raylib Python** — all previous Qt C++ UI patches are invalid
2. **MADS framework** — Modular Assistive Driving System replaces older engagement logic
3. **Driving model manager** — model selection is now managed differently
4. **New cereal schema** — message structures may have changed

Before making any UI changes, inspect the actual source code of the installed branch
to confirm the current file structure. The locations described above are based on
documentation — verify them in the actual repository.
