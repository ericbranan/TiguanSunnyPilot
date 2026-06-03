# Volkswagen Tiguan — openpilot/sunnypilot Research Notes

**Research date:** 2026-06-03  
**Vehicle:** 2022 Volkswagen Tiguan SE

---

## 1. Vehicle Identification

| Field | Value |
|---|---|
| Make | Volkswagen |
| Model | Tiguan |
| Generation | MK2 (2nd generation) |
| Model year | 2022 |
| Trim | SE |
| Platform | MQB (Modularer Querbaukasten) |
| openpilot identifier | `VOLKSWAGEN_TIGUAN_MK2` |
| Chassis codes | 5N, AD, AX, BW |
| WMI | VOLKSWAGEN_EUROPE_SUV / VOLKSWAGEN_MEXICO_SUV |
| Mass (spec) | 1715 kg |
| Wheelbase (spec) | 2.74 m |
| Steer ratio (spec) | 15.6 |

---

## 2. Support Status

| System | Status |
|---|---|
| openpilot (commaai/openpilot) | **Supported** — Tiguan MK2 (2018-24), `opendbc/car/volkswagen/values.py` |
| sunnypilot | **Supported** — follows opendbc upstream |
| Required features | ACC (Adaptive Cruise Control) + Lane Assist (HCA/LKAS) |
| Harness | VW J533 — available from comma.ai shop for Tiguan 2018-24 |
| Platform config | `VolkswagenMQBPlatformConfig` |
| Longitudinal type | Stock ACC (openpilot follows, not overrides, by default) |

---

## 3. Harness Information

The 2022 Tiguan SE uses the **VW J533 gateway harness**.

The J533 gateway connects at the CAN gateway (module J533) located in the driver's
footwell, just above the steering column. The comma device's relay intercepts the
extended CAN bus between the gateway and downstream modules.

**Source:** comma.ai shop product listing, openpilot wiki (Volkswagen)

### 2022 Model Year Note

Earlier research indicated that 2022+ Volkswagen models may have a combined CAN
gateway/BCM (Body Control Module), which was stated to be "supported in software but
without a dedicated harness from the comma store." However:

- The comma.ai shop lists "Volkswagen Tiguan 2018-24" with the J533 harness **available**
- Third-party J533 harnesses (e.g., xnor.shop, konik.ai) explicitly list MQB support
- The opendbc values.py lists 2022 in the supported range without special notes

**Action required:** Physically verify the harness connector in the footwell before purchase.
The vehicle's gateway module location and connector type should match J533 documentation.
If uncertain, cross-reference with the openpilot VW wiki or the sunnypilot community forum.

---

## 4. CAN Bus Architecture

Volkswagen MQB vehicles use multiple CAN buses. The J533 gateway sits at the junction:

| Bus | Description | openpilot Access |
|---|---|---|
| Extended CAN | Main ADAS bus (ACC, HCA/LKAS, camera) | Yes — J533 intercepts |
| Powertrain CAN | Engine, transmission | Read-only via gateway |
| Comfort/Body CAN | Windows, lights, BCM | Read-only via gateway |
| Diagnostic bus (K-Line / CAN) | DIAG port | OBD2 — separate |

The J533 intercept point gives openpilot read access to most vehicle signals and write access
to HCA (steering) and ACC setpoints through the extended CAN bus.

---

## 5. Relevant Code Files

### opendbc Repository (submodule at `opendbc_repo/`)

| File | Purpose |
|---|---|
| `opendbc/car/volkswagen/values.py` | Car definitions, fingerprints, specs, platform config |
| `opendbc/car/volkswagen/carstate.py` | Reads CAN signals → car state struct |
| `opendbc/car/volkswagen/carcontroller.py` | Sends CAN commands (steering, ACC) |
| `opendbc/car/volkswagen/pqcarstate.py` | PQ platform car state (older VW) |
| `opendbc/car/volkswagen/pqcarcontroller.py` | PQ platform controller |
| `opendbc/car/volkswagen/fingerprints.py` | CAN message fingerprints (confirmed present in current sunnypilot/opendbc master) |
| `opendbc/dbc/vw_mqb_2010.dbc` | DBC: CAN message definitions for MQB platform |
| `opendbc/dbc/vw_pq35_pq46_superb.dbc` | DBC: PQ platform (not relevant to 2022 Tiguan) |
| `opendbc/car/volkswagen/interface.py` | OpenPilot car interface entry point |

**Important:** The opendbc submodule structure can change between upstream releases.
After the initial upstream fetch, verify these paths exist at the pinned submodule commit:
```bash
ls opendbc_repo/opendbc/car/volkswagen/
ls opendbc_repo/opendbc/dbc/ | grep vw
```

### sunnypilot Main Repo

| File | Purpose |
|---|---|
| `selfdrive/car/volkswagen/` | SP may have VW-specific overrides (verify in fork) |
| `sunnypilot/selfdrive/` | SP-specific driving logic |
| `sunnypilot/sunnylink/` | SunnyLink integration |
| `selfdrive/ui/` | Qt UI code (being replaced by Raylib in v2026+) |
| `sunnypilot/models/` | SP driving models |

### Safety-Critical Files (Do Not Modify)
- `panda/` submodule — panda safety code
- `panda/board/safety/safety_volkswagen.h` — VW-specific panda safety rules

---

## 6. DBC Files

The primary DBC file for the 2022 Tiguan SE is:

```
opendbc_repo/opendbc/dbc/vw_mqb_2010.dbc
```

This file defines:
- CAN message IDs and names
- Signal names, byte offsets, scaling factors
- Relevant messages include:
  - `LH_EPS_03` — EPS torque and HCA status (steering)
  - `ACC_02`, `ACC_06` — ACC setpoints and status
  - `ESP_21` — wheel speeds
  - `TSK_06` — engine torque/speed
  - `GRA_ACC_01` — cruise control stalk buttons

**Do not modify DBC files** without fully understanding the impact on CAN parsing across
all supported vehicles. DBC changes affect every vehicle that uses that bus.

---

## 7. Fingerprinting

openpilot identifies the vehicle via "fingerprinting" — matching observed CAN message IDs
and their properties to known vehicle fingerprints.

For the Tiguan MK2, fingerprints are defined in:
```
opendbc_repo/opendbc/car/volkswagen/fingerprints.py
```

The fingerprint includes lists of expected CAN message IDs on each bus. If the device
enters "dashcam only" mode, fingerprint recognition has failed. This can happen if:
- The vehicle's CAN messages differ from the expected fingerprint
- The harness connection is not seated correctly
- The firmware version differs from what the fingerprint was trained on

If fingerprinting fails for the 2022 SE, check the openpilot VW community for known
alternative fingerprint entries or firmware-related quirks.

---

## 8. Panda Safety Hooks

The panda safety model for VW MQB is defined in:
```
panda/board/safety/safety_volkswagen.h
```

Key safety constraints (from openpilot panda code):
- **Steering torque limit:** Maximum steering torque is capped — any request above this
  is blocked by panda hardware, regardless of software request
- **Speed-dependent limits:** Steering inputs are constrained by vehicle speed
- **Longitudinal:** By default, openpilot does NOT send longitudinal commands to VW MQB —
  it relies on the factory ACC system and sends only setpoint adjustments
- **Driver torque override:** If driver applies sufficient steering torque, openpilot
  disengages (safety feature — cannot be disabled from software)

These limits **cannot be changed via fork customization**. They are enforced in the
panda firmware which runs independently of the Comma 3X software.

---

## 9. Longitudinal Control Notes

Three distinct longitudinal control modes exist. These are often confused:

| Mode | How it works | VW MQB support | Panda involvement |
|---|---|---|---|
| **Factory stock ACC** | Vehicle's OEM ACC handles all braking/acceleration; openpilot only reads state | Always available if vehicle has ACC | Read-only on ACC bus |
| **sunnypilot Custom Stock Longitudinal** | openpilot adjusts ACC setpoint more aggressively (speed limits, vision-based deceleration) — still uses factory ACC actuators | **Available for VW MQB in sunnypilot** | Setpoint adjustments within panda limits |
| **openpilot direct longitudinal** | OP sends raw braking/acceleration CAN commands, bypassing factory ACC | Experimental and NOT validated for 2022 Tiguan SE | Would require panda to approve longitudinal commands for VW — not current default |

For this fork:
- Use sunnypilot Custom Stock Longitudinal if desired — it is within bounds
- Do NOT enable direct openpilot longitudinal without explicit upstream community validation for the 2022 Tiguan SE

**ACC Type — Critical Open Question:**

The 2022 Tiguan SE ACC type (High or Low) affects fundamental behavior:
- `ACC High` (Traffic Jam Assist / Follow to Stop): follows to a complete stop, auto-resumes
- `ACC Low` (standard ACC): requires driver to resume after a complete stop

**How to determine ACC type before driving:**
1. Check the original window sticker or original order summary for "Traffic Jam Assist" or "Follow to Stop"
2. Check the owner's manual Adaptive Cruise Control section — ACC High vehicles describe stop-and-go behavior
3. In the vehicle, check `Settings → Assist systems → Adaptive Cruise Control` for stop-and-go options
4. Via OBD2: Use VCDS or OBD11 to read the gateway (J533) module coding — the ACC configuration is encoded there

---

## 10. Lateral Tuning Notes

The default steer ratio for the Tiguan MK2 is **15.6** (from opendbc values.py).
The default mass is **1715 kg**.

These values affect:
- Lateral PID/torque controller tuning
- Lane centering aggressiveness
- Turn anticipation

The sunnypilot Neural Network Lateral Controller (NNLC), introduced in v2025.001.000+,
uses a torque-based model that is less sensitive to exact steer ratio values than
the older PID-based approach. Custom tuning of steer ratio is generally not needed
with NNLC.

**Do not change lateral tuning parameters without extended testing** — incorrect values
cause unstable or oscillatory lane centering.

---

## 11. Known Limitations

| Limitation | Notes |
|---|---|
| Trim level | SE trim support not separately verified — should be same as base MQB |
| 2022 hardware variant | May have combined gateway/BCM — verify harness physically before purchase |
| ACC type | 2022 SE ACC High vs Low not confirmed — determine before first use (see §9) |
| sunnypilot Custom Stock Longitudinal | Available for MQB but not yet tested on 2022 Tiguan SE |
| Direct openpilot longitudinal | NOT supported/validated for VW MQB — do not enable |
| Emergency Lane Assist override | Tiguan has its own ELA that may interfere in some scenarios |
| US firmware | US-spec Tiguan may have different firmware — fingerprint should handle this |

---

## 12. Safe Possible Tweaks (This Fork)

| Tweak | Risk | Notes |
|---|---|---|
| Adjust lane centering aggressiveness via params | Low | Change a param value, not code |
| Change lane departure alert threshold | Low | Param change |
| Adjust ACC follow distance profile | Low | Param change |
| Modify onroad UI display elements | Low | UI code, no car behavior |
| Add custom HUD overlay information | Medium | UI code, possible upstream conflict |
| Change default map/speed limit settings | Low | Param defaults |
| Custom alert sounds or tones | Low | Asset replacement |

---

## 13. Unsafe / Not Recommended Tweaks

| Item | Reason |
|---|---|
| Modify panda safety_volkswagen.h | Bypasses hardware safety enforcement |
| Increase max steering torque | Can cause violent lane correction — injury risk |
| Enable openpilot longitudinal for MQB | Experimental; not validated for 2022 Tiguan |
| Modify DBC files | Affects all MQB vehicles; high regression risk |
| Disable driver monitoring | Removes safety-critical alerting |
| Spoof vehicle fingerprint | Causes wrong safety profile to be applied |
| Change steer ratio significantly (>20%) | Can cause oscillation or overcorrection |
| Override ACC to use OP longitudinal | Requires thorough safety validation |

---

## 14. Open Questions

- [ ] What is the exact ACC type (High/Low) on the 2022 Tiguan SE?
- [ ] Does the 2022 SE have a separate J533 gateway, or is it combined with BCM?
- [ ] Which firmware version does the US-spec 2022 Tiguan SE run on J533?
- [ ] Are there known quirks for 2022 model year on sunnypilot community forum?
- [ ] Does sunnypilot's MQB custom stock longitudinal work on the 2022 Tiguan SE?
- [ ] What is the current pairing/onboarding experience for the 2022 Tiguan SE with sunnypilot?

---

## 15. Research Sources

- opendbc/car/volkswagen/values.py — confirmed Tiguan MK2 (2018-24) support
- comma.ai shop — J533 harness listed for Tiguan 2018-24
- openpilot wiki (Volkswagen) — J533 gateway, MQB architecture
- sunnypilot docs/CARS.md — Tiguan (2018-24) with ACC & Lane Assist
- sunnypilot CHANGELOG.md — VW MQB platform support noted across versions
- openpilot panda safety — safety_volkswagen.h (hardware-enforced limits)
