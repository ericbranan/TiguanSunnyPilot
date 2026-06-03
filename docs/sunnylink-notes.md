# SunnyLink Notes

**Dashboard URL:** https://sunnylink.ai/dashboard  
**Research date:** 2026-06-03

---

## 1. What SunnyLink Is

SunnyLink is sunnypilot's first-party cloud management platform. It provides a web-based
control center for comma devices running sunnypilot, accessible remotely from any browser.

Official description: "A secure, remote access platform for sunnypilot devices — settings
management, driving model selection, device monitoring, configuration backup/restore."

---

## 2. What SunnyLink Can Manage

| Capability | Details |
|---|---|
| Settings sync | Remotely read and write sunnypilot parameter values |
| Driving model selection | Browse and switch between neural net driving models |
| Device status monitoring | See if device is online, its software version, last trip |
| Configuration backup | Save a snapshot of all device params |
| Configuration restore | Push a saved param snapshot to device |
| Remote settings database | community.sunnylink.wiki — 66+ documented settings |
| Multiple device management | Manage all your paired comma devices from one dashboard |
| Real-time parameter changes | Changes sync to device next time it connects |

---

## 3. What SunnyLink Cannot Manage

| Limitation | Notes |
|---|---|
| Install a custom fork | Cannot change the software source URL remotely |
| Access private GitHub repos | No GitHub integration for private repositories |
| SSH access or shell commands | SunnyLink is settings-layer only, not a shell |
| Factory reset the device | Must be done on device or via SSH |
| Flash firmware or panda | Hardware-level operations not supported |
| Force immediate reboots | Device changes apply on next device cycle |
| Substitute for SSH in recovery | SunnyLink requires the device to be online and running |

---

## 4. SunnyLink and Custom Forks

SunnyLink pairs with any device running sunnypilot — including custom forks — as long as
the fork maintains the SunnyLink integration code.

The sunnypilot codebase has a `/sunnypilot/sunnylink/` directory containing the
SunnyLink connectivity layer. As long as this is not modified or broken in the custom fork,
SunnyLink pairing should continue to work normally.

**Critical:** Do not modify `/sunnypilot/sunnylink/` files. These handle device registration,
settings sync, and the SunnyLink pairing protocol. Breaking this code would require a
device re-pair and could cause unexpected settings behavior.

---

## 5. Dashboard Options Observed

Based on public documentation and community descriptions (direct dashboard inspection
requires the user's logged-in browser session):

- Device list with online/offline status
- Software version per device
- Settings panel with toggle controls
- Driving model library and model switching
- Backup/restore configuration snapshots
- Pair new device (requires pairing code from device)

---

## 6. SunnyLink and This Fork

After installing the custom fork (`custom/eric-main`), re-pairing steps:

1. On device, go to `Settings → SunnyLink` and check connection status
2. If disconnected, generate a new pairing code on device
3. In SunnyLink dashboard, pair device with new pairing code
4. Verify settings sync by making a small change in dashboard and confirming it applies

The custom fork should NOT break SunnyLink unless the `/sunnypilot/sunnylink/` code
is modified or the fork is too far behind upstream (SunnyLink API changes can break
older fork versions).

---

## 7. SunnyLink Settings Backup — Recommended Steps

Before switching from official sunnypilot to the custom fork:

1. Log in to SunnyLink dashboard at sunnylink.ai/dashboard
2. Open the device settings for the Comma 3X
3. Use the backup/export function to save the current configuration
4. Store this backup file locally (not in the git repo — it may contain device identifiers)
5. After installing the custom fork, restore the configuration from backup

---

## 8. Known Limitations and Warnings

- SunnyLink requires an active internet connection on the device and your browser
- SunnyLink changes are not reflected in the git repo — they are device-side params
- If SunnyLink pushes a setting that conflicts with a custom param default in your fork,
  the SunnyLink value will override (SunnyLink writes to the same params store)
- Custom parameter values that you set in your fork's code as defaults may be
  overwritten by SunnyLink if a user changes them via the dashboard
- There is no version lock between SunnyLink and a specific fork version — a SunnyLink
  settings push always targets the current device param store

---

## 9. Resources

- Dashboard: https://sunnylink.ai/dashboard
- Settings wiki: https://community.sunnypilot.ai (requires account)
- sunnylink-frontend source: https://github.com/sunnypilot/sunnylink-frontend
