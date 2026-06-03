# Safety Boundaries

This document defines the non-negotiable safety constraints for all changes made in the
`ericbranan/TiguanSunnyPilot` fork. It is referenced before every code change and
must be reviewed in full before any first drive with the custom fork installed.

**Vehicle:** 2022 Volkswagen Tiguan SE  
**Device:** Comma 3X  
**This is vehicle control software. Mistakes can injure or kill people.**

---

## 1. Non-Negotiable Safety Limits

The following rules apply to ALL changes in this fork without exception:

### 1.1 panda Safety is Inviolable

The panda device enforces safety limits in hardware-running firmware, independently of
the Comma 3X software. No software change in this fork can override panda.

- **Never modify** `panda/board/safety/safety_volkswagen.h`
- **Never modify** any file in `panda/board/safety/`
- **Never flash custom panda firmware** outside of official openpilot/sunnypilot releases
- If panda firmware needs updating, use only the official update provided by sunnypilot

**When panda blocks a command:** If panda rejects a steering or longitudinal request,
the ADAS will disengage with an alert. This is expected safety enforcement — it means
the request was outside the validated safety envelope. Do not treat panda rejections
as bugs to work around. Pull over if needed, review logs, and investigate the root cause.

### 1.2 Steering Torque Limits

The panda safety code enforces maximum steering torque for the VW MQB platform. These
limits are calibrated based on the physical capabilities of the vehicle's EPS system
and safety margins.

- The steer ratio (15.6) and mass (1715 kg) in `values.py` are physical constants, not
  tuning parameters. Do not change them unless you have measured your specific vehicle.
- Do not add code to request torque above what panda will allow.

### 1.3 Driver Monitoring Cannot Be Disabled

Driver monitoring (camera-based attentiveness detection) is a safety feature. It must
not be disabled, weakened, or circumvented.

- Do not modify `selfdrive/monitoring/`
- Do not change driver monitoring alert thresholds to suppress warnings
- Do not modify the distracted driver alert logic

### 1.4 Longitudinal Safety

The 2022 Tiguan SE uses stock longitudinal control (factory ACC). openpilot does not
directly control braking or acceleration on this vehicle.

sunnypilot's Custom Stock Longitudinal (available for VW MQB) adjusts ACC setpoints
but does NOT override the factory ACC actuators. This is acceptable in this fork.
Direct openpilot longitudinal (where OP controls braking via CAN) is not validated
for the 2022 Tiguan SE — do not enable it.

- Do not enable direct openpilot longitudinal without explicit upstream community
  validation for the 2022 Tiguan SE
- Do not modify longitudinal MPC parameters

See `docs/volkswagen-tiguan-research.md` §9 for the full longitudinal mode breakdown.

### 1.5 No Safety Feature Removal

Do not remove or weaken any safety-critical UI element or alert:
- Forward collision warning
- Lane departure warning (adjusting threshold via param is acceptable)
- Disengagement alerts
- Boot-time safety disclaimers

### 1.6 DBC Files Must Not Be Modified

DBC (Database CAN) files define how every CAN signal is decoded across ALL vehicles
using that bus. A single wrong bit offset, byte order, or scaling factor will silently
corrupt every signal decoded from that message — including vehicle speed, steering angle,
brake state, and ACC status — with no error indication. This affects every MQB vehicle,
not just the Tiguan.

**Never modify:** `opendbc_repo/opendbc/dbc/vw_mqb_2010.dbc` or any other DBC file
without upstream review and a dedicated PR to sunnypilot/opendbc.

---

## 2. What Counts as Cosmetic (LOW Risk)

Changes that only affect visual presentation and do not alter any vehicle control signal:

- Changing text labels, font sizes, colors
- Moving UI elements on screen
- Adding informational overlays (speed, compass, gear indicator)
- Replacing audio alert sounds with equivalent-volume alternatives
- Modifying the boot splash screen or logo
- Changing the UI theme or color scheme
- Adding a custom "fork name" label in the settings

**Testing required:** Boot device and visually verify. No driving required.

---

## 3. What Counts as Behavioral (MEDIUM Risk)

Changes that affect how sunnypilot responds but stay within existing safety boundaries:

- Changing default parameter values (follow distance, lane offset)
- Adjusting speed limit source priorities
- Enabling/disabling sunnypilot feature flags via params
- Changing the default driving model
- Adjusting the lateral offset (lane centering position)
- Enabling sunnypilot Custom Stock Longitudinal for VW MQB (setpoint adjustments)

All parameter changes in this fork are MEDIUM risk — not LOW — because parameter
values affect real driving behavior. Every param change must be:
1. Documented in `docs/change-log.md`
2. Tested through the relevant testing ladder stages before highway use

**Testing required:** Parked device test first, then low-speed controlled test,
then quiet residential road before highway.

---

## 4. What Counts as Safety Critical (HIGH / CRITICAL Risk)

Changes that affect:
- How CAN messages are parsed or sent
- How the vehicle's steering, braking, or acceleration is commanded
- How safety limits are enforced
- How the driver monitoring system works
- How the update mechanism or watchdog works
- The panda firmware or safety model
- DBC files (signal definitions)

**Action:** Do not make these changes in this fork. Only accept them via upstream sync
from the official sunnypilot repository after the sunnypilot team's review.

---

## 5. Changes That Must Never Be Made in This Fork

| Change | Reason |
|---|---|
| Disable or weaken panda safety checks | Hardware safety enforcement — directly dangerous |
| Increase steering torque beyond panda limits | Physical damage to EPS / injury risk |
| Spoof vehicle fingerprint | Applies wrong safety profile to vehicle |
| Disable driver monitoring | Removes attentiveness safety check |
| Suppress disengagement alerts | User won't know when OP is not in control |
| Enable direct openpilot longitudinal (not validated) | Not validated for this vehicle |
| Modify DBC files without upstream review | Silently corrupts ALL CAN signals on that bus |
| Fork update mechanism to skip security checks | Allows untested code on the vehicle |
| Commit any cryptographic keys or tokens | Security risk |
| Push to sunnypilot upstream | Shares private changes with official repository |

---

## 6. Testing Ladder

Before any change is driven on a road, it must pass every applicable stage.

### Stage 1 — Code Review (Desk)
- Read the full diff carefully
- Confirm the change is in the allowed categories above
- Confirm no safety-critical files are touched
- Confirm no secrets are staged: `git diff | grep -iE "(token|key|password)"` (or use gitleaks)
- Pass criteria: diff reviewed, nothing unexpected changed

### Stage 2 — Static Device Test (Parked, Engine Off)
- Install the change on the device
- Boot and verify no crash loops or boot loops
- Navigate all screens to confirm UI is intact
- Check that settings load correctly
- Pass criteria: device boots clean, all screens navigate without error

### Stage 3 — Static Vehicle Test (Parked, Ignition On)
- With vehicle parked, engine running, in park
- Confirm the vehicle is fingerprinted correctly (openpilot shows ready state, not dashcam-only)
- Confirm alerts are functional
- Do NOT engage the ADAS system at any point in this stage
- Pass criteria: vehicle fingerprinted, ready state shown, no unexpected alerts

### Stage 4 — Slow-Speed Controlled Environment
- Private driveway or empty parking lot only
- Maximum speed 15 mph / 24 km/h
- Passenger in seat as spotter, hands near wheel
- Engage lane centering only — no highway scenarios
- Disengage immediately if anything feels wrong
- Pass criteria: lane centering functions as expected, disengagement is clean

### Stage 5 — Quiet Residential Roads (New)
- Residential roads only — no traffic pressure, low speed limits (≤25 mph / 40 km/h)
- Spotter still recommended for first drive on this stage
- Test disengagement behavior explicitly (hands-on override, blinker disengage)
- Test a speed transition (30 mph to stop and back)
- Pass criteria: stable behavior over ≥3 uneventful passes through the area

### Stage 6 — Normal Road Use
- Only after Stages 1–5 pass cleanly
- First normal drive on a low-traffic route
- Build up to highway speeds over multiple sessions
- Pass criteria: no unexpected behavior over ≥3 normal drives

---

## 7. Public Road Testing of Unverified Changes

**Do not test unverified behavioral changes on public roads.**

Any change that has not passed Stages 1 through 4 must not be driven on public roads.
Vehicle control software faults on public roads endanger other people.

For the initial installation of the custom fork (even if only cosmetic changes), complete
Stage 3 at minimum before any road use.

---

## 8. Incident Response

If the custom fork causes unexpected vehicle behavior during a drive:

1. Immediately take manual control of steering and braking
2. Pull over safely and stop the vehicle
3. Do NOT re-engage the ADAS system until the root cause is identified
4. Install the rollback build (see `docs/device-install-and-rollback.md`)
5. Retrieve drive logs: `ssh comma@<ip>` → `/data/media/0/realdata/` (most recent route)
6. Document the incident in `docs/change-log.md`
7. Do not re-install the failing change without identifying and fixing the root cause

---

## 9. Contributing Real Bugs Upstream

If you discover a genuine bug in the VW interface code (e.g., wrong fingerprint for a
new firmware version, incorrect CAN signal offset), the correct path is upstream, not a
private fork fix:

1. Reproduce the bug with logs and a clear description
2. Isolate the minimal patch required to fix it
3. Test the fix statically (Stages 1–3 at minimum)
4. Open an issue or PR against sunnypilot `master` or the appropriate opendbc repo
5. Reference your device logs as evidence
6. Do not carry the fix privately in this fork unless upstream maintainers explicitly
   advise waiting for a release cycle

---

## 10. This Document Is Not Optional

Every commit to `custom/tiguan-ui`, `custom/tiguan-params`, or `custom/eric-main`
must be reviewed against this document before it is installed on the device.

If any change is uncertain about its risk level, treat it as CRITICAL until proven
otherwise by upstream documentation or community confirmation.
