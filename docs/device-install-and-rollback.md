# Device Install and Rollback Guide

**Vehicle:** 2022 Volkswagen Tiguan SE  
**Device:** Comma 3X  
**Current Software:** sunnypilot dev (dev.sunnypilot.ai)

---

## STOP — Pre-Conditions Before Any Installation

Do not install the fork until ALL of the following are true:

- [ ] Private fork (`ericbranan/TiguanSunnyPilot`) exists and the target branch has been pushed
- [ ] Branch `custom/eric-main` has been reviewed and is based on a known-good sunnypilot commit
- [ ] The current device software version has been recorded (see "Record Current State" below)
- [ ] The official sunnypilot rollback URL is known and tested in your head
- [ ] The vehicle is parked safely and you have time to troubleshoot a failed boot

---

## 1. Current Install Method (Official sunnypilot dev)

The device currently runs sunnypilot via the dev install URL:

```
dev.sunnypilot.ai
```

This points to a prebuilt nightly build of sunnypilot. The device auto-updates from this URL on the update schedule configured in the device settings.

---

## 2. Custom Fork Install Method

### Option A — Public Fork (Simplest, Recommended for Initial Testing)

If the fork `ericbranan/TiguanSunnyPilot` is set to **public** on GitHub:

Install URL:
```
install.sunnypilot.ai/fork/ericbranan/custom-eric-main
```

This uses sunnypilot's own fork installer service. Enter this URL on the device at:
`Settings → Software → Change Software → Enter URL`

Or during device setup when prompted for Custom Software.

**Note:** The fork must be public. The installer cannot authenticate to a private GitHub repo.

### Option B — Private Fork via SSH (For Private Repos)

If the fork remains private, installation requires SSH access to the device.

Prerequisites:
1. Device has SSH enabled: `Settings → Network → Advanced → Enable SSH`
2. Your GitHub SSH public key is added to the device: `Settings → Network → SSH Keys → Add GitHub Username`
3. You can SSH to the device: `ssh comma@<device-ip-address>`

Install command (run on device via SSH):
```bash
cd /data
mv openpilot openpilot.bak_$(date +%Y%m%d)   # backup current install
git clone --depth=1 -b custom/eric-main https://github.com/ericbranan/TiguanSunnyPilot.git openpilot
cd openpilot
git submodule update --init --recursive
sudo reboot
```

**Important:** `--depth=1` gets only the latest commit (faster download, less storage).  
Remove `--depth=1` if you need full git history on device for debugging.

For a truly private repo, use an SSH deploy key instead of HTTPS:
```bash
git clone --depth=1 -b custom/eric-main git@github.com:ericbranan/TiguanSunnyPilot.git openpilot
```
(Requires SSH deploy key set up on the device for your GitHub repo.)

---

## 3. SunnyLink Role

SunnyLink (`sunnylink.ai`) is the remote management dashboard for sunnypilot. It can:
- Remotely configure sunnypilot settings and toggles
- Backup and restore parameter configurations
- Monitor device status and drive data
- Push settings changes remotely

SunnyLink **cannot**:
- Install a custom fork directly from the dashboard
- Change the software source URL remotely (must be done on device)
- Access a private GitHub repository
- Replace the need for SSH for low-level recovery

After installing the custom fork, re-pair with SunnyLink if it disconnects.

---

## 4. Record Current Device State

Before any software change, record the current state. SSH into device and run:

```bash
# Software version
cat /VERSION 2>/dev/null || cat /data/params/d/GitCommit

# Current branch
cat /data/params/d/GitBranch

# Current remote
cat /data/params/d/GitRemote

# Check if stock or custom fork
ls -la /data/openpilot/.git/

# Record installed params (backup)
cp -r /data/params /data/params_backup_$(date +%Y%m%d)
```

Save this output somewhere safe (not committed to the repo).

---

## 5. Backup Steps

Before installing any new software:

```bash
# SSH into device
ssh comma@<device-ip>

# Backup openpilot directory
cd /data
cp -r openpilot openpilot.bak_$(date +%Y%m%d_%H%M)

# Backup params
cp -r params params.bak_$(date +%Y%m%d_%H%M)

# Note current software version
cat /VERSION
```

On the device, the backup will persist across reboots unless the user deliberately removes it. Storage on the Comma 3X is limited (~250GB total), so clean up old backups periodically.

---

## 6. Verification Steps After Installation

After reboot following a new install:

1. Device should boot to the sunnypilot UI (not a crash loop)
2. Check that the software shows the correct fork and branch:
   - Settings → Software → shows correct version/commit
3. Check that vehicle fingerprint is recognized (requires being in the car with ignition on)
4. Check that SunnyLink reconnects and shows the device
5. Drive in a safe, low-speed, parking lot environment first before highway use

Via SSH:
```bash
cat /data/params/d/GitBranch      # should show custom/eric-main
cat /data/params/d/GitRemote      # should show ericbranan/TiguanSunnyPilot
cat /data/params/d/GitCommit      # note commit hash
```

---

## 7. Rollback to Official sunnypilot dev

If the custom fork fails to boot or behaves unexpectedly, rollback to official sunnypilot immediately.

### Method 1 — If Device Still Boots (Recommended)

On device UI:
```
Settings → Software → Change Software → Enter URL
```
Enter: `dev.sunnypilot.ai`

Then: `Settings → Software → Download` → install → reboot.

### Method 2 — Via SSH (If UI is Broken)

```bash
ssh comma@<device-ip>
cd /data
rm -rf openpilot
git clone --depth=1 -b __nightly https://github.com/sunnypilot/sunnypilot.git openpilot
# OR restore from backup:
# cp -r openpilot.bak_YYYYMMDD openpilot
sudo reboot
```

### Method 3 — Factory Reset (Last Resort)

On device (hold power button → Factory Reset), or via the recovery mode. This will erase all params including calibration, SunnyLink pairing, and drive routes.

---

## 8. Emergency Recovery Notes

- The Comma 3X can always be factory reset via the power button long-press menu.
- Factory reset does NOT brick the device — it reinstalls the base AGNOS OS.
- After factory reset, simply enter `dev.sunnypilot.ai` as the install URL to get back to official sunnypilot.
- The device hardware (camera, sensors, GPS) is not affected by software issues.

---

## 9. Update Workflow for the Custom Fork

After the fork is installed on device:

1. Make changes on `custom/eric-main` branch in the development environment
2. Test changes in a safe static environment (parked, no driving)
3. Push updated `custom/eric-main` to `origin`
4. SSH into device and pull:

```bash
ssh comma@<device-ip>
cd /data/openpilot
git fetch origin
git checkout custom/eric-main
git pull origin custom/eric-main
git submodule update --recursive
sudo reboot
```

Or if the device was installed with depth=1 and needs a fresh install:
```bash
cd /data
rm -rf openpilot
git clone --depth=1 -b custom/eric-main https://github.com/ericbranan/TiguanSunnyPilot.git openpilot
cd openpilot && git submodule update --init --recursive
sudo reboot
```

---

## 10. Known Risks

| Risk | Mitigation |
|---|---|
| Fork fails to boot | Always keep rollback URL handy; maintain device backup |
| Custom branch diverges too far from upstream | Regular upstream syncs (monthly min) |
| VW fingerprinting fails after update | Check opendbc_repo submodule version; may need to update |
| SunnyLink disconnects | Re-pair via SunnyLink dashboard after reinstall |
| Private fork install breaks offline | Always have SSH access available |
| Commit secret to fork | Use `git secret scan` before push; review staged changes |
