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

### 1.2 Steering Torque Limits

The panda safety code enforces maximum steering torque for the VW MQB platform. These limits
are calibrated based on the physical capabilities of the vehicle's EPS (Electric Power
Steering) system and safety margins.

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
directly control braking or acceleration on this vehicle — it adjusts ACC setpoints.

- Do not enable experimental openpilot longitudinal unless:
  a) It has been explicitly validated for the 2022 Tiguan SE by the upstream community
  b) You have done extensive static and low-speed testing first
  c) You accept full personal responsibility for the results
- Do not modify longitudinal MPC parameters

### 1.5 No Safety Feature Removal

Do not remove or weaken any safety-critical UI element or alert:
- Forward collision warning
- Lane departure warning (unless simply adjusting the threshold via param)
- Disengagement alerts
- Boot-time safety disclaimers

---

## 2. What Counts as Cosmetic (Low Risk)

Changes that only affect visual presentation and do not alter any vehicle control signal
or safety-relevant parameter:

- Changing text labels, font sizes, colors
- Moving UI elements on screen
- Adding informational overlays (speed, compass, gear indicator)
- Replacing audio alert sounds with equivalent-volume alternatives
- Modifying the boot splash screen or logo
- Changing the UI theme or color scheme
- Adding a custom "fork name" label in the settings

**Testing required:** Boot device and visually verify. No driving required.

---

## 3. What Counts as Behavioral (Medium Risk)

Changes that affect how sunnypilot responds or what it does, but within existing
safety boundaries:

- Changing default parameter values (follow distance, lane offset)
- Adjusting speed limit source priorities
- Enabling/disabling sunnypilot feature flags via params
- Changing the default driving model
- Adjusting the lateral offset (lane centering position)

**Testing required:** Parked device test first, then low-speed controlled road test before
highway use.

---

## 4. What Counts as Safety Critical (High / Critical Risk)

Changes that affect:
- How CAN messages are parsed or sent
- How the vehicle's steering, braking, or acceleration is commanded
- How safety limits are enforced
- How the driver monitoring system works
- How the update mechanism or watchdog works
- The panda firmware or safety model

**Action:** Do not make these changes in this fork. Only accept them via upstream sync
from the official sunnypilot repository after they have passed the sunnypilot team's
review.

---

## 5. Changes That Must Never Be Made in This Fork

| Change | Reason |
|---|---|
| Disable or weaken panda safety checks | Hardware safety enforcement — directly dangerous |
| Increase steering torque beyond panda limits | Physical damage to EPS / injury risk |
| Spoof vehicle fingerprint | Applies wrong safety profile to vehicle |
| Disable driver monitoring | Removes attentiveness safety check |
| Suppress disengagement alerts | User won't know when OP is not in control |
| Enable undocumented experimental longitudinal | Not validated for this vehicle |
| Modify DBC files without upstream review | Can corrupt CAN parsing for all MQB vehicles |
| Fork update mechanism to skip security checks | Creates vulnerability for untested code |
| Commit any cryptographic keys or tokens | Security risk |
| Push to sunnypilot upstream | Would share private changes with official repository |

---

## 6. Testing Ladder

Before any change touches the road, it must pass each stage:

### Stage 1 — Code Review (Desk)
- Read the diff carefully
- Confirm the change is in the allowed categories above
- Confirm no safety-critical files are touched
- Search for unintended changes: `git diff` review

### Stage 2 — Static Device Test (Parked, Engine Off)
- Install the change on the device
- Boot and verify no crash loops
- Navigate all screens to confirm UI is intact
- Check that settings load correctly

### Stage 3 — Static Vehicle Test (Parked, Ignition On)
- With the vehicle parked and engine idling
- Confirm that the vehicle is fingerprinted correctly
- Confirm that openpilot enters a normal ready state (not dashcam-only)
- Confirm alerts are functioning (test forward alert simulation if available)
- Do NOT engage the ADAS system

### Stage 4 — Slow-Speed Controlled Environment
- Private driveway or empty parking lot only
- Maximum speed 15 mph / 24 km/h
- Someone in passenger seat as spotter
- Engage lane centering only — no highway scenarios
- Verify the change behaves as expected at low speed
- Disengage immediately if anything feels wrong

### Stage 5 — Normal Road Use
- Only after Stages 1-4 pass cleanly
- First drive on quiet roads, not highway
- Build up to normal use over multiple sessions

---

## 7. Public Road Testing of Unverified Changes

**Do not test unverified behavioral changes on public roads.**

Any change that has not passed Stages 1 through 4 must not be driven on public roads.
This is not a legal recommendation — it is a safety requirement. Vehicle control software
faults on public roads endanger other people.

For the initial installation of the custom fork (even if it contains only cosmetic changes),
complete Stage 3 at minimum before any road use.

---

## 8. Incident Response

If the custom fork causes unexpected vehicle behavior during a drive:

1. Immediately take manual control of steering and braking
2. Pull over safely and stop
3. Do NOT re-engage the ADAS system until the root cause is identified
4. Install the rollback build (see `docs/device-install-and-rollback.md`)
5. Investigate the cause by reviewing the drive logs via SunnyLink or ssh
6. Document the incident in `docs/change-log.md`
7. Do not install the failing change again without understanding the root cause

---

## 9. This Document Is Not Optional

Every commit to `custom/tiguan-ui`, `custom/tiguan-params`, or `custom/eric-main`
should be reviewed against this document before merging into `custom/eric-main`.

If any change is uncertain about its risk level, treat it as CRITICAL until proven otherwise.
