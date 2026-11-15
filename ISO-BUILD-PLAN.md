# Building the EmComm Tools ISO

How to build the EmComm Tools (ETC) ISO: Debian 12 with ETC installed, built
with Debian/live-build, installed with Calamares. The build needs internet; the
ISO doesn't.

In short: install Debian 12, clone this repository, run `sudo ./build.sh`, run
`./install.sh` in the build's root shell, then `exit` to make the ISO.

## Setup

You need a machine or VM (4+ CPUs, 6 GB RAM, 100 GB disk) with internet.

1. **Install Debian 12**, minimal: under Software selection, untick both
   **Debian desktop environment** and **GNOME**. Installer images:
   [debian.org/releases/bookworm/debian-installer](https://www.debian.org/releases/bookworm/debian-installer/)
   (the small `netinst` image is enough). **Leave the root password empty**:
   the build needs your user to have `sudo`, and Debian gives it only then.

2. **Get the repository:**

   ```bash
   sudo apt install -y git
   git clone https://github.com/thetechprepper/emcomm-tools-os-community.git
   cd emcomm-tools-os-community
   git checkout <release tag or branch>
   ```

<details>
<summary>Only if <code>sudo</code> says you're not in the sudoers file</summary>

A root password was set during install. Fix it as root, using the root
password and your login name:

```bash
su -
apt install -y sudo git
adduser youruser sudo
exit
```

**Then log out and back in** (or reboot): `sudo` works only after a new login.

</details>

### Optional: the xara modem

xara is no longer distributed by its developer, so the build can't download
it. To include it, bring your own copy of its source code, packaged as described
in [scripts/xara.md](scripts/xara.md):

1. Package the source as `xara-VERSION.tar.gz` (e.g. `xara-0.1.3.tar.gz`),
   with a single top-level folder named `xara`
2. Copy the tarball into `scripts/`:

   ```bash
   tar -czf ~/src/xara-0.1.3.tar.gz -C ~/src xara
   cp ~/src/xara-0.1.3.tar.gz scripts/
   ```

## Build

1. **Start the build:**

   ```bash
   cd live-build
   sudo ./build.sh
   ```

   First, `build.sh` uses Debian's live-build to create a fresh Debian 12
   system in a folder, downloading and installing its packages. This takes
   15 minutes or more; then it opens the build's root shell inside that system.

2. **Install EmComm Tools:** when the build's root shell opens, type this and
   answer the ETC questions (map tiles and Navit map):

   ```bash
   ./install.sh
   ```

   When it's done, it shows what to do next. To also be asked for a Wikipedia
   (`.zim`) file and shown the WINE notes, run `ET_EXPERT=1 ./install.sh`
   instead.

3. **Optional: check the install** with ETC's test suite:

   ```bash
   cd ../tests && ./run-test-suite.sh
   ```

4. **Optional: customize.** In the build's root shell, install extra packages
   with `apt install`, add files, or change settings. Everything done there
   ends up in the ISO.

5. **Type `exit`.** This leaves the shell and automatically starts making the
   ISO. The whole build takes about 45 minutes.

## Output

When the build finishes, it shows where the ISO is and how many `install.sh`
steps failed. Both the ISO and the full log (`build.log`) are in
`/var/tmp/etc-live-build/`. If any steps failed, check them in `build.log`
before using the ISO.

To install the ISO, see [docs/INSTALL-GUIDE.md](docs/INSTALL-GUIDE.md).

The release name comes from the newest ETC release tag on your checkout. It
names the ISO, its volume ID, the boot menu, the installer and the conky panel.
For tag
`emcomm-tools-os-community-20261111-r7-build37`:

| Checkout | Release | ISO |
|---|---|---|
| The tag itself | `ETC_R7_BUILD37` | `emcomm-tools-os-community-20261111-r7-build37-amd64.hybrid.iso` |
| Newer commits | `ETC_R7_BUILD37-<commit>` | `...-r7-build37-<commit>-amd64.hybrid.iso` |
| Uncommitted changes | `...-modified` added | `...-modified-amd64.hybrid.iso` |

## Build options

| Option | How | Default |
|---|---|---|
| Build folder | `sudo ET_WORK_DIR=/path ./build.sh` | `/var/tmp/etc-live-build` (emptied each build) |

## What's in your ISO

Your ISO is your own build, with the choices you made while building it:

| Item | |
|---|---|
| Debian 12, GNOME, EmComm Tools | Installed |
| Map tiles, Navit map, Wikipedia (`.zim`) files, xara | Those chosen while building |
| Any additional customizations you've made | Included |
| VARA | Scripts and docs; added after install (see `scripts/wine.txt`) |
| GRUB for UEFI and BIOS | Carried, for offline installs |
| Live session | Starts the installer; closing it leaves the desktop. Login `user` / `live` (Debian's default); SSH off |
| This repository | Read-only copy in `/opt/emcomm-tools-os-community` |
| Accounts, SSH host keys, machine-id, logs | None; generated during the install |

## Where things are

- `live-build/build.sh`: sets up and runs `lb config` / `lb build`.
- `live-build/config/package-lists/emcomm-tools.list.chroot`: base packages.
- `live-build/config/hooks/normal/0900-emcomm-tools.hook.chroot`: the build's
  root shell for `install.sh`, then cleanup.
- `live-build/config/hooks/normal/0910-grub-pc-pool.hook.binary`: BIOS GRUB
  for offline installs.
- `live-build/config/hooks/normal/0920-boot-menu.hook.binary`: ETC's name and
  release in the boot menus.
- `live-build/config/includes.chroot/etc/calamares/`: installer settings.
- `live-build/config/includes.chroot/usr/lib/live/config/`: live-session-only
  setup (installer without a password, installer at startup).
