# Customization Map

This document maps potential customization areas in the sunnypilot codebase,
categorized by risk level and specific to the `ericbranan/TiguanSunnyPilot` fork.

**All file paths in this document were verified against sunnypilot master (commit dfc3c98,
fetched 2026-06-03). The codebase uses Raylib Python UI (v2026.001.000+); the old Qt C++
UI paths are no longer relevant.**

**Risk scale:**
- `LOW` — cosmetic or param change; safe to experiment
- `MEDIUM` — behavioral but bounded; test carefully before driving
- `HIGH` — affects core driving logic; do not change without deep code review
- `CRITICAL` — safety boundaries; off-limits in this fork

---

## Category 1 — Safe UI / Visual Changes (Branch: `custom/tiguan-ui`)

### 1.1 Home Screen Fork Label

| Field | Value |
|---|---|
| File | `selfdrive/ui/layouts/home.py` |
| Line | `231` |
| Current code | `brand = "sunnypilot"` |
| Purpose | Version string shown top-right of home screen: `"sunnypilot v2026.001.000"` |
| Change | `brand = "TiguanSP"` |
| Risk | LOW |
| Test | Boot device (or run UI) — check top-right of home screen |
| Rollback | `git revert <commit>` |

### 1.2 Onroad HUD Renderer (base)

| Field | Value |
|---|---|
| File | `selfdrive/ui/onroad/hud_renderer.py` |
| Purpose | Draws current speed, set speed, steering wheel icon, status color |
| Customizable | Color constants in `Colors` dataclass (lines ~38-50) |
| Example | Change `ENGAGED = rl.Color(128, 216, 166, 255)` (green) to a different shade |
| Risk | LOW (color only) — MEDIUM if changing layout geometry |
| Test | Engage sunnypilot in parking lot, verify HUD display |

### 1.3 sunnypilot Onroad UI Elements

These live in `selfdrive/ui/sunnypilot/onroad/` and are Tiguan-relevant:

| File | Element | Risk |
|---|---|---|
| `hud_renderer.py` | sunnypilot-specific HUD overlays | LOW–MEDIUM |
| `speed_renderer.py` | Speed display style | LOW |
| `turn_signal.py` | Visual turn signal indicators | LOW |
| `blind_spot_indicators.py` | Blind spot warning overlays | LOW |
| `smart_cruise_control.py` | Cruise control state display | LOW |
| `speed_limit.py` | Speed limit display element | LOW |
| `rocket_fuel.py` | Acceleration bar | LOW |
| `road_name.py` | Road name overlay | LOW |
| `rainbow_path.py` | Rainbow path effect | LOW (cosmetic) |

### 1.4 Settings Screen Labels

| Area | File | Risk |
|---|---|---|
| Main settings menu | `selfdrive/ui/layouts/settings/settings.py` | LOW |
| Software settings | `selfdrive/ui/layouts/settings/software.py` | LOW |
| Device settings | `selfdrive/ui/layouts/settings/device.py` | LOW |
| Toggle labels | `selfdrive/ui/layouts/settings/toggles.py` | LOW |
| sunnypilot settings hub | `selfdrive/ui/sunnypilot/layouts/settings/settings.py` | LOW |
| Visuals settings | `selfdrive/ui/sunnypilot/layouts/settings/visuals.py` | LOW |
| Steering settings | `selfdrive/ui/sunnypilot/layouts/settings/steering.py` | LOW |
| Cruise settings | `selfdrive/ui/sunnypilot/layouts/settings/cruise.py` | LOW |
| Display settings | `selfdrive/ui/sunnypilot/layouts/settings/display.py` | LOW |
| VW brand settings | `selfdrive/ui/sunnypilot/layouts/settings/vehicle/brands/volkswagen.py` | LOW–MEDIUM |

### 1.5 VW Brand Settings (currently empty, safe to add items)

The VW brand settings hook (`volkswagen.py`) currently has an empty `update_settings()`
method. This is the correct place to add Tiguan-specific settings items that appear in
the Vehicle Settings panel only when a VW is detected.

---

## Category 2 — sunnypilot Parameter Defaults (Branch: `custom/tiguan-params`)

Parameter defaults are set at device initialization. The params system lives in
`openpilot/common/params.py` (base) and sunnypilot may extend it.

Visual toggle params enabled by default benefit Tiguan drivers immediately:

| Param Key | Default in SP | Recommended for Tiguan | Effect | Risk |
|---|---|---|---|---|
| `BlindSpot` | `0` (off) | `1` (on) | Shows BSM warnings if car has BSM | MEDIUM |
| `ShowTurnSignals` | `0` (off) | `1` (on) | Visual turn signal indicator on HUD | LOW |
| `StandstillTimer` | `0` (off) | `1` (on) | Timer shown when stopped | LOW |
| `TrueVEgoUI` | `0` (off) | `1` (on) | Shows wheel-speed-based true speed | LOW |
| `RocketFuel` | `0` (off) | `1` (on) | Real-time accel/decel bar | LOW |
| `RoadNameToggle` | `0` (off) | `1` (on) | Shows road name (requires OSM data) | LOW |
| `LongitudinalPersonality` | Standard | Standard | Follow distance mode | LOW |

**Where to set defaults:** Look for a param initialization file in
`sunnypilot/` or a first-boot setup path. The sunnypilot car params sync is in
`sunnypilot/selfdrive/car/sync_sunnylink_params.py`.

**Important:** SunnyLink dashboard can override these values. See `docs/sunnylink-notes.md`.

---

## Category 3 — Volkswagen-Specific Behavior

### 3.1 VW Brand Settings Panel

| File | `selfdrive/ui/sunnypilot/layouts/settings/vehicle/brands/volkswagen.py` |
|---|---|
| Current state | Empty — `update_settings(self): pass` |
| Safe to add | VW-specific param toggles via `self.items.append(toggle_item_sp(...))` |
| Risk | MEDIUM — adds behavior settings; test each one |

### 3.2 Vehicle Platform Selector

| File | `selfdrive/ui/sunnypilot/layouts/settings/vehicle/platform_selector.py` |
|---|---|
| Purpose | Lets user select the vehicle platform manually if fingerprinting fails |
| Risk | MEDIUM — if wrong platform selected, wrong safety profile applied |

### 3.3 opendbc VW Interface Files (submodule — do not modify)

These files exist in the `opendbc_repo` submodule and are **read-only** for this fork:

| File | Purpose |
|---|---|
| `opendbc_repo/opendbc/car/volkswagen/values.py` | Car specs, fingerprints, platform config |
| `opendbc_repo/opendbc/car/volkswagen/carstate.py` | CAN → car state parser |
| `opendbc_repo/opendbc/car/volkswagen/carcontroller.py` | Sends CAN commands |
| `opendbc_repo/opendbc/car/volkswagen/fingerprints.py` | Vehicle ID fingerprints |
| `opendbc_repo/opendbc/dbc/vw_mqb_2010.dbc` | MQB CAN message definitions |

**These files are in a submodule. Modifying them in this fork requires maintaining a
fork of the opendbc submodule, which adds significant complexity. Do not attempt this
without a specific need and deep understanding of DBC/CAN implications.**

---

## Category 4 — Vehicle Interface Code (Do Not Modify)

| Area | Files | Risk | Note |
|---|---|---|---|
| Car state reader | `opendbc_repo/opendbc/car/volkswagen/carstate.py` | HIGH | CAN parsing — wrong values corrupt signals |
| Car controller | `opendbc_repo/opendbc/car/volkswagen/carcontroller.py` | HIGH | CAN output — wrong values move the car |
| Platform config | `opendbc_repo/opendbc/car/volkswagen/values.py` | HIGH | Specs affect torque/speed control |
| Fingerprint data | `opendbc_repo/opendbc/car/volkswagen/fingerprints.py` | HIGH | Wrong fingerprint → wrong safety profile |

---

## Category 5 — Safety-Critical Code (Off-Limits)

| Area | Files | Risk |
|---|---|---|
| panda safety hooks | `panda/board/safety/safety_volkswagen.h` | CRITICAL |
| panda firmware | `panda/board/` | CRITICAL |
| Longitudinal MPC | `selfdrive/controls/lib/*mpc*` | CRITICAL |
| Lateral MPC | `selfdrive/controls/lib/lateral*` | CRITICAL |
| Driver monitoring | `selfdrive/monitoring/` | CRITICAL |
| Process manager/watchdog | `system/manager/` | CRITICAL |
| DBC files | `opendbc_repo/opendbc/dbc/*.dbc` | CRITICAL |
| Launch scripts | `launch_*.sh` | CRITICAL |
| SConstruct | `SConstruct` | CRITICAL |

---

## Planned Changes Summary

See `docs/planned-ui-changes.md` for exact code diffs.

### Priority 1 — Fork Label (ready to implement)
- **File:** `selfdrive/ui/layouts/home.py:231`
- **Change:** `brand = "sunnypilot"` → `brand = "TiguanSP"`
- **Branch:** `custom/tiguan-ui`

### Priority 2 — Default Params for Tiguan (ready to implement once param init path confirmed)
- Set `BlindSpot`, `ShowTurnSignals`, `StandstillTimer`, `TrueVEgoUI` on by default
- **Branch:** `custom/tiguan-params`

### Priority 3 — VW Brand Settings Panel (research needed)
- Add Tiguan-useful toggles to `volkswagen.py`
- Need to verify which params are valid for VW MQB before adding
- **Branch:** `custom/tiguan-params` or `custom/tiguan-ui`

---

## Merge Conflict Risk Assessment

| Area | Upstream Change Frequency | Our Risk |
|---|---|---|
| `selfdrive/ui/layouts/home.py` | MEDIUM (UI evolving) | Low impact — single-line change |
| `selfdrive/ui/onroad/hud_renderer.py` | MEDIUM | Modest risk — colors are stable |
| `selfdrive/ui/sunnypilot/onroad/` | LOW-MEDIUM | SP-specific files change less often |
| `selfdrive/ui/sunnypilot/layouts/settings/vehicle/brands/volkswagen.py` | LOW | Minimal upstream activity |
| Param defaults | LOW | Stable section of codebase |
