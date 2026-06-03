# Device Install and Rollback Guide

**Vehicle:** 2022 Volkswagen Tiguan SE  
**Device:** Comma 3X  
**Current Software:** sunnypilot (dev.sunnypilot.ai)

---

## STOP — Pre-Conditions Before Any Installation

Do not install the fork until ALL of the following are true:

- [ ] Fork (`ericbranan/TiguanSunnyPilot`) exists and target branch is pushed to origin
- [ ] `custom/eric-main` has been reviewed and is based on a known-good sunnypilot commit
- [ ] Current device software version has been recorded (see §4 below)
- [ ] SSH access to the device is verified (see §0 below)
- [ ] Official sunnypilot rollback URL is confirmed: `dev.sunnypilot.ai`
- [ ] Device is parked safely and you have time to troubleshoot a failed boot
- [ ] AGNOS version on device is recorded and confirmed compatible with the fork branch

---

## 0. SSH Preflight — Verify Before Touching the Device

Every install and rollback procedure requires SSH. Confirm it works before starting.

**Find the device IP:**

1. On device: `Settings → Network` — the IP address is shown
2. Alternatively: check your home router's DHCP client table for a device named `comma`

**Enable SSH on device (if not already):**
`Settings → Network → Advanced → Enable SSH`

**Add your GitHub SSH key to the device:**
`Settings → Network → SSH Keys → Add GitHub Username` → type your GitHub username → press Enter

**Test SSH:**
```bash
ssh comma@<device-ip-address>
# Expected: a shell prompt on the device, e.g.: comma@comma:~$
```

If SSH fails, do not proceed with the install. Resolve SSH access first.

---

## 1. Current Install Method (Official sunnypilot dev)

The device runs sunnypilot via the dev install URL: `dev.sunnypilot.ai`

This URL serves a prebuilt AGNOS installer for the C3X (tizi). The device checks for
updates on the schedule configured in Settings → Software.

Note: `dev.sunnypilot.ai` is a device-side installer endpoint, not a Git branch.
It is not directly equivalent to the `__nightly` Git branch (see §7 for rollback details).

---

## 2. Custom Fork Install Method

### Install Branch Naming

The branch `custom/eric-main` contains a forward slash. The `install.sunnypilot.ai/fork/`
URL installer may not handle slash-separated branch names correctly (the slash adds a URL
path segment).

**Two options:**

**Option A — Maintain a flat install branch (public fork, URL installer):**
```bash
# After rebuilding custom/eric-main, create or update the flat install branch:
git checkout custom/eric-main
git checkout -b eric-main      # no slash — safe for URL path
git push origin eric-main:eric-main
```
Install URL:
```
install.sunnypilot.ai/fork/ericbranan/eric-main
```

**Option B — Install directly via SSH (public or private fork):**
Use the exact branch name `custom/eric-main` in the SSH clone command.
No URL installer needed. This works regardless of fork visibility.

---

### Option A — URL Installer (Public Fork, Flat Branch)

On device, navigate to:
`Settings → Software → Change Software → Enter URL`

Enter:
```
install.sunnypilot.ai/fork/ericbranan/eric-main
```

Or during initial device setup, select Custom Software and enter the URL above.

The fork must be **public** on GitHub for this to work. The installer cannot
authenticate to private repos.

---

### Option B — SSH Clone (Public or Private Fork)

Prerequisites: SSH working (see §0), device has internet access.

```bash
ssh comma@<device-ip>

# Backup current install first (see §5)
cd /data
mv openpilot openpilot.bak_$(date +%Y%m%d_%H%M)

# Clone the fork — shallow clone for speed and storage efficiency
# Note: --depth=1 on the main clone does NOT propagate to submodules automatically.
git clone --depth=1 -b custom/eric-main \
  https://github.com/ericbranan/TiguanSunnyPilot.git openpilot

# Initialize submodules with shallow depth (requires git 2.10+)
# sunnypilot submodules include panda, opendbc_repo, tinygrad_repo (large)
cd openpilot
git submodule update --init --recursive --depth=1

sudo reboot
```

**Comma 3X git version check:**
```bash
git --version   # confirm >= 2.10 for --depth in submodule update
```

---

### Option B — Private Fork via Deploy Key

For a private fork, use a dedicated read-only deploy key instead of your personal
GitHub SSH key. This limits exposure if the device is compromised.

**Generate deploy key (run on your development machine, NOT on device):**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/tiguan_sunnypilot_deploy \
  -C "tiguan-sunnypilot-readonly" -N ""
# Creates:
#   ~/.ssh/tiguan_sunnypilot_deploy      (private key — goes on device)
#   ~/.ssh/tiguan_sunnypilot_deploy.pub  (public key — goes to GitHub)
```

**Add public key to GitHub:**
GitHub → ericbranan/TiguanSunnyPilot → Settings → Deploy keys → Add deploy key  
Paste the content of `~/.ssh/tiguan_sunnypilot_deploy.pub`  
Check "Allow read access" only — do NOT check write access.

**Copy private key to device:**
```bash
scp ~/.ssh/tiguan_sunnypilot_deploy comma@<device-ip>:/home/comma/.ssh/
ssh comma@<device-ip> chmod 600 /home/comma/.ssh/tiguan_sunnypilot_deploy
```

**Configure SSH on device to use deploy key:**
```bash
ssh comma@<device-ip>
cat >> /home/comma/.ssh/config << 'EOF'
Host github-tiguan
  HostName github.com
  User git
  IdentityFile /home/comma/.ssh/tiguan_sunnypilot_deploy
  IdentitiesOnly yes
EOF
```

**Clone using deploy key:**
```bash
git clone --depth=1 -b custom/eric-main \
  git@github-tiguan:ericbranan/TiguanSunnyPilot.git openpilot
```

---

## 3. SunnyLink Role

SunnyLink (`sunnylink.ai`) is the remote settings management dashboard. After a fork install:

- SunnyLink may show the device as offline if the pairing was lost during the install
- Re-pair by generating a new pairing code on the device and entering it in the dashboard

**SunnyLink cannot:** install forks, change software source URLs, or access private repos.

See `docs/sunnylink-notes.md` for full capabilities.

---

## 4. Record Current Device State

SSH into device and capture the current state before any software change:

```bash
ssh comma@<device-ip>

# Software version and commit
cat /data/params/d/GitCommit
cat /data/params/d/GitBranch
cat /data/params/d/GitRemote

# AGNOS version (required for compatibility tracking)
cat /VERSION 2>/dev/null || cat /etc/comma/agnos_version 2>/dev/null || uname -r

# Record to a local file on your dev machine (not committed to the repo):
# ssh comma@<device-ip> 'echo "GitCommit: $(cat /data/params/d/GitCommit)"
#   echo "GitBranch: $(cat /data/params/d/GitBranch)"
#   echo "AGNOS: $(cat /VERSION)"' > ~/tiguan-device-state-$(date +%Y%m%d).txt
```

---

## 5. Backup Steps

Always backup before installing:

```bash
ssh comma@<device-ip>
cd /data

# Backup openpilot directory
cp -r openpilot openpilot.bak_$(date +%Y%m%d_%H%M)

# Backup params (settings, calibration, SunnyLink pairing)
cp -r params params.bak_$(date +%Y%m%d_%H%M)

# Verify backup exists before continuing
ls -lh /data/openpilot.bak_*
```

Storage note: the Comma 3X has limited internal storage. Check available space with
`df -h /data` and remove old backups periodically.

---

## 6. Verification Steps After Installation

After reboot:

1. Device boots to sunnypilot UI (no crash loop or boot-loop)
2. Check version: Settings → Software shows the expected commit or version
3. Check via SSH:
```bash
cat /data/params/d/GitBranch      # should show: custom/eric-main
cat /data/params/d/GitRemote      # should show: ericbranan/TiguanSunnyPilot
cat /data/params/d/GitCommit      # note the commit hash
```
1. Confirm vehicle fingerprint (requires ignition on, engine running):
   - openpilot should show ready state, not dashcam-only mode
1. Confirm SunnyLink reconnects (see §3 for re-pairing if needed)

---

## 7. SunnyLink Re-Pairing After Install

If SunnyLink shows the device offline after a fork install:

1. On device: `Settings → SunnyLink` → check connection status
2. If disconnected: `Settings → SunnyLink → Pair device` → a pairing code appears
3. In browser: go to `sunnylink.ai/dashboard` → add device → enter pairing code
4. Verify: the device appears online in the dashboard within ~1 minute

---

## 8. Rollback to Official sunnypilot

### Method 1 — URL Installer (Preferred — Device UI Still Works)

On device: `Settings → Software → Change Software → Enter URL`

Enter: `dev.sunnypilot.ai`

Then: Settings → Software → Download → install → reboot.

`dev.sunnypilot.ai` is a sunnypilot-hosted AGNOS installer endpoint for C3X dev builds.
It is the same endpoint used to install sunnypilot originally.

### Method 2 — SSH Clone (Device UI Broken or Unresponsive)

For SSH rollback, use the `release-tizi` branch — the stable prebuilt branch for C3X
(confirmed to exist in sunnypilot). Do NOT use `__nightly` for rollback; it is a
nightly prebuilt that may be unstable.

```bash
ssh comma@<device-ip>
cd /data

# Restore from backup if available (fastest option)
rm -rf openpilot
cp -r openpilot.bak_YYYYMMDD_HHMM openpilot
sudo reboot

# OR: clone official stable branch for C3X
rm -rf openpilot
git clone --depth=1 -b release-tizi \
  https://github.com/sunnypilot/sunnypilot.git openpilot
cd openpilot
git submodule update --init --recursive --depth=1
sudo reboot
```

### Method 3 — Factory Reset (Last Resort)

Hold the power button → select Factory Reset, or use the device recovery mode.

**Warning:** Factory reset erases all params including SunnyLink pairing, calibration,
and drive routes. After reset, enter `dev.sunnypilot.ai` as the install URL.

---

## 9. Subsequent Updates to the Custom Fork

After the fork is running on device, update it when `custom/eric-main` is updated:

```bash
ssh comma@<device-ip>
cd /data/openpilot

git fetch origin
git checkout custom/eric-main
git pull origin custom/eric-main:custom/eric-main
git submodule update --recursive --depth=1
sudo reboot
```

Or re-clone for a clean install:
```bash
cd /data
rm -rf openpilot
git clone --depth=1 -b custom/eric-main \
  https://github.com/ericbranan/TiguanSunnyPilot.git openpilot
cd openpilot && git submodule update --init --recursive --depth=1
sudo reboot
```

---

## 10. Drive Log Retrieval

After a problematic drive, retrieve logs for analysis:

```bash
ssh comma@<device-ip>

# Routes are stored here — each directory is one drive segment
ls /data/media/0/realdata/

# Copy a specific route to your dev machine
scp -r comma@<device-ip>:/data/media/0/realdata/<route-id> ~/tiguan-logs/
```

Logs can also be viewed via SunnyLink dashboard (road-facing camera replays and
metadata) without SSH access.

---

## 11. Known Risks

| Risk | Mitigation |
|---|---|
| Fork fails to boot | Always keep rollback URL handy; backup before install |
| Custom branch diverges too far | Monthly upstream syncs; test on each sync |
| VW fingerprinting fails after update | Check opendbc_repo submodule SHA; may need to update |
| SunnyLink disconnects | Re-pair via dashboard after reinstall |
| Private fork install broken offline | Always have SSH access confirmed before install |
| AGNOS version mismatch | Record AGNOS version before and after; compare with sunnypilot release notes |
| Submodule clone exceeds device storage | Use `--depth=1` on submodule update; clear old backups |
| git < 2.10 on device (no submodule --depth) | Run `git --version` on device before install; update git if needed |
