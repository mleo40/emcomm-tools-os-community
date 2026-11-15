# Building the EmComm Tools ISO

How to build the EmComm Tools ISO: Debian 12 with ETC installed, built with
Debian/live-build, installed with Calamares. The build needs internet; the ISO
doesn't.

In short: install Debian 12, clone this repository, run `sudo ./build.sh`, run
`./install.sh` in the root shell it opens, then `exit` to make the ISO.

## Setup

On a minimal Debian 12 system with a git client (no desktop needed; a VM is
fine: 4+ CPUs, 6 GB RAM, 100 GB disk), about 60 GB free, internet, and `sudo`.
Debian 12 installer images:
[debian.org/releases/bookworm/debian-installer](https://www.debian.org/releases/bookworm/debian-installer/)
(the small `netinst` image is enough).

```bash
git clone https://github.com/thetechprepper/emcomm-tools-os-community.git
cd emcomm-tools-os-community
git checkout <release tag or branch>
```

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

```bash
cd live-build
sudo ./build.sh
```

live-build sets up Debian 12, then opens a root shell inside the ISO's system,
in `/opt/emcomm-tools-os-community/scripts`:

```bash
./install.sh
```

Other customizations can be made in the same shell before leaving it: install
extra packages with `apt install`, add files, or change settings. Everything
in this shell ends up in the ISO.

**Typing `exit` leaves the shell and automatically starts making the ISO.**
The whole build takes about 45 minutes.

VARA is added after install; see `scripts/wine.txt`.

## Output

In `/var/tmp/etc-live-build/`: the ISO (about 4.6 GB) and `build.log`.
`build.sh` ends with the number of failed `install.sh` steps; check any in
`build.log` before using the ISO.

The release name comes from the newest ETC tag on your checkout. It names the
ISO, its volume ID, the boot menu, the installer and the conky panel. For tag
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

## What's in the ISO

| Item | |
|---|---|
| Debian 12, GNOME, EmComm Tools | Installed |
| Maps, zim files, xara | Those chosen while building |
| Any additional customizations you've made | Included |
| VARA | Scripts and docs; added after install |
| GRUB for UEFI and BIOS | Carried, for offline installs |
| Live session | Starts the installer; closing it leaves the desktop. Login `user` / `live` (Debian's default); SSH off |
| This repository | Read-only copy in `/opt/emcomm-tools-os-community`, no git history; `install.sh` not executable |
| Accounts, SSH host keys, machine-id, logs | None; generated per install |

## Where things are

- `live-build/build.sh`: sets up and runs `lb config` / `lb build`.
- `live-build/config/package-lists/emcomm-tools.list.chroot`: base packages.
- `live-build/config/hooks/normal/0900-emcomm-tools.hook.chroot`: the root
  shell for `install.sh`, then cleanup.
- `live-build/config/hooks/normal/0910-grub-pc-pool.hook.binary`: BIOS GRUB
  for offline installs.
- `live-build/config/hooks/normal/0920-boot-menu.hook.binary`: ETC's name and
  release in the boot menus.
- `live-build/config/includes.chroot/etc/calamares/`: installer settings.
- `live-build/config/includes.chroot/usr/lib/live/config/`: live-session-only
  setup (installer without a password, installer at startup).
