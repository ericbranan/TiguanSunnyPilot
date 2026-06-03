# Planned UI Changes

This file documents exact code changes for the `custom/tiguan-ui` and `custom/tiguan-params`
branches. All paths are relative to the repository root.

**All changes verified against sunnypilot master commit `dfc3c98` (2026-06-03).**

---

## Change 1 — Fork Identification Label

**Branch:** `custom/tiguan-ui`  
**File:** `selfdrive/ui/layouts/home.py`  
**Lines:** 230–233  
**Risk:** LOW — cosmetic only, no behavior change

### Before

```python
def _get_version_text(self) -> str:
    brand = "sunnypilot"
    description = self.params.get("UpdaterCurrentDescription")
    return f"{brand} {description}" if description else brand
```

### After

```python
def _get_version_text(self) -> str:
    brand = "TiguanSP"
    description = self.params.get("UpdaterCurrentDescription")
    return f"{brand} {description}" if description else brand
```

### Effect
The version string in the top-right corner of the home screen changes from
`sunnypilot v2026.001.000` to `TiguanSP v2026.001.000`.

This makes it immediately clear which fork is installed on the device.

### Rollback
```bash
git revert <commit-sha>
# or manually restore:
# brand = "sunnypilot"
```

---

## Change 2 — Default Visual Toggles for Tiguan

**Branch:** `custom/tiguan-params`  
**Location:** TBD — param initialization path (see note below)  
**Risk:** LOW–MEDIUM — enables display features; no driving behavior change

### Purpose
Enable visually useful toggles by default so they are active on first boot.
These can all be toggled off by the user at any time in sunnypilot settings.

### Params to Enable by Default

| Param | Current Default | New Default | Reason |
|---|---|---|---|
| `ShowTurnSignals` | `0` | `1` | Visual turn indicators on HUD — useful on highways |
| `StandstillTimer` | `0` | `1` | Standstill timer shows elapsed stopped time |
| `TrueVEgoUI` | `0` | `1` | Shows true wheel-speed velocity, not cluster speed |
| `RocketFuel` | `0` | `1` | Real-time accel/decel bar — informative display |
| `BlindSpot` | `0` | `1` | BSM warnings on HUD — the 2022 Tiguan SE has BSM |

**Note on `BlindSpot`:** This requires the vehicle to have BSM (Blind Spot Monitoring).
The 2022 Tiguan SE is expected to have BSM as standard equipment. If BSM is not present,
enabling this param has no effect — no warnings will appear. Safe to enable.

### How to Set Param Defaults

The correct mechanism needs to be confirmed. Options:

**Option A — Params initialization file:**
If sunnypilot has a first-run or default-params script, add entries there.
Look for: `sunnypilot/selfdrive/car/sync_sunnylink_params.py` or a `params_manager.py`.

**Option B — Migration/init script:**
Some openpilot forks use a migration file like `selfdrive/selfdrived/migration.py`
or similar to set param defaults on first boot.

**Option C — Direct param write in car interface:**
The VW brand settings class (`volkswagen.py`) has an `update_settings()` method that
fires during init. This could write param defaults if the param is not yet set:

```python
from openpilot.common.params import Params

class VolkswagenSettings(BrandSettings):
    def __init__(self):
        super().__init__()

    def update_settings(self):
        p = Params()
        defaults = {
            "ShowTurnSignals": b"1",
            "StandstillTimer": b"1",
            "TrueVEgoUI": b"1",
            "RocketFuel": b"1",
            "BlindSpot": b"1",
        }
        for key, value in defaults.items():
            if p.get(key) is None:
                p.put(key, value)
```

**This approach only sets the value if the param is not already set** — so it
respects user changes and SunnyLink overrides. Safe pattern.

**Requires verification:** Confirm that `update_settings()` is called at the right
time during boot for this to work reliably. Check `vehicle/platform_selector.py`
and `vehicle/__init__.py` for call sites.

---

## Change 3 — VW Brand Settings Panel Items (Future)

**Branch:** `custom/tiguan-params`  
**File:** `selfdrive/ui/sunnypilot/layouts/settings/vehicle/brands/volkswagen.py`  
**Risk:** MEDIUM — adds visible settings items; test each toggle

### Purpose
Add Tiguan-useful settings to the VW Vehicle Settings panel. These appear in
`Settings → Vehicle → Brand-specific settings` only when VW is detected.

### Candidate Items

1. **MADS quick toggle** — shortcut to the MADS toggle for VW users
2. **Blinker Pause Lateral Control** — pause steering when signaling below a set speed
3. **Intelligent Cruise Button Management** — if supported for VW MQB

### Verification Needed
- Confirm which params apply to VW MQB before adding any settings item
- Check whether ICBM is available on VW MQB in the current SP version
- The `SteeringLayout` in `steering.py` already has VW-compatible items —
  avoid duplicating them here

### Implementation Template

```python
from openpilot.common.params import Params
from openpilot.system.ui.sunnypilot.widgets.list_view import toggle_item_sp
from openpilot.selfdrive.ui.sunnypilot.layouts.settings.vehicle.brands.base import BrandSettings


class VolkswagenSettings(BrandSettings):
    def __init__(self):
        super().__init__()

    def update_settings(self):
        # Items added here appear in the VW brand settings section
        self.items = [
            toggle_item_sp(
                param="BlinkerPauseLateralControl",
                title=lambda: "Pause Steering on Turn Signal",
                description="Temporarily suspend lane centering when a turn signal is active.",
            ),
        ]
```

**Do not implement until the following are verified:**
- `BlinkerPauseLateralControl` is available and functional for VW MQB
- The `update_settings()` call actually renders `self.items` in the UI
  (trace from `platform_selector.py`)

---

## Change 4 — Engaged Color Tweak (Optional / Low Priority)

**Branch:** `custom/tiguan-ui`  
**File:** `selfdrive/ui/onroad/hud_renderer.py`  
**Lines:** ~40 (Colors dataclass)  
**Risk:** LOW — purely cosmetic

### Motivation
The default engaged color (green `(128, 216, 166)`) can be tweaked to a slightly
different hue for personal preference. No functional impact.

### Current
```python
ENGAGED = rl.Color(128, 216, 166, 255)
ENGAGED_BG = rl.Color(128, 216, 166, 204)
```

### Possible adjustment (blue-tinted green — calmer appearance)
```python
ENGAGED = rl.Color(100, 200, 200, 255)
ENGAGED_BG = rl.Color(100, 200, 200, 204)
```

**Note:** Only do this if you find the default green visually fatiguing. Not a
priority. Leave at default unless specifically desired.

---

## Implementation Order

1. **Change 1** (fork label) — implement first; zero risk, validates dev workflow
2. **Change 2, Option C** (param defaults via `volkswagen.py`) — implement after
   confirming that `update_settings()` fires correctly at boot
3. **Change 3** (VW brand settings) — only after verifying which params work for VW MQB
4. **Change 4** (color tweak) — personal preference; lowest priority

---

## Notes on Implementation Environment

The `sunny-upstream` branch (local only) contains the full sunnypilot source tree at
commit `dfc3c98`. Custom branches should be based on `sunny-upstream` in a dev
environment where a full (non-shallow) clone is available.

In the current cloud environment (shallow clone), the `sunny-upstream` branch cannot
be pushed to `origin`. The custom changes in this file are ready to apply once a full
dev environment is configured.

See `docs/eric-fork-overview.md` §10 for first-clone setup commands.
