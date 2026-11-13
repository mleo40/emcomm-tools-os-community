# Building EmComm Tools ISO images

How to build the EmComm Tools ISO: Debian 12 with ETC installed, built with
Debian/live-build, installed with Calamares. The build needs internet; the ISO
doesn't. Why and what changed: [CHANGES-OVERVIEW.md](CHANGES-OVERVIEW.md).

## What you need

- Debian 12 (a VM is fine: 4 CPUs, 6 GB RAM, 100 GB disk), about 60 GB free,
  internet, `sudo` and `git`. `build.sh` installs `live-build` if missing.

## Build

```bash
git clone https://github.com/thetechprepper/emcomm-tools-os-community.git
cd emcomm-tools-os-community
git checkout <release tag or branch>
cd live-build
sudo ./build.sh
```

About 45 minutes. Only git-tracked files are used; uncommitted changes to them
go into the ISO (`build.sh` warns). Output in `/var/tmp/etc-live-build/`:
`emcomm-tools-os-community-<date>-amd64.hybrid.iso` (about 4.8 GB) and
`build.log`. `build.sh` ends with the `install.sh` exit code and failed steps;
check any in `build.log` before publishing.

## Build options

| Option | How | Default |
|---|---|---|
| Release name (conky panel, JS8Call MyInfo) | `sudo ET_RELEASE=ETC_R8_BUILD1 ./build.sh` | From the last ETC tag, e.g. `ETC_R7_BUILD37` |
| Build folder | `sudo ET_WORK_DIR=/path ./build.sh` | `/var/tmp/etc-live-build` (emptied each build; download cache kept) |

**Download cache.** The Debian packages live-build downloads (a few GB) are kept
in `<build folder>/cache` between builds, so rebuilds don't fetch them again.
Useful when rebuilding often (testing changes) or on a slow or metered
connection. apt still uses Debian's current package index, so the ISO is the
same with or without it. `install.sh`'s own downloads aren't cached. For a
fully fresh download, delete the `cache` folder.

`ET_EXPERT` (r7's offline Wikipedia download) doesn't work in an ISO build: it
asks which file to download, and the build can't answer.

## What's in the ISO

| Item | In the ISO |
|---|---|
| Debian 12, GNOME, EmComm Tools | Installed |
| Maps | Global map only (80 MB). Adding other maps: to be decided |
| Encryption tools install files | Carried, not installed. Opt-in on the installer's **Optional software** page, or later: `sudo /opt/emcomm-tools-os-community/scripts/install-crypto.sh --offline` |
| GRUB for UEFI and BIOS | Carried, for offline installs |
| Live session login | `user` / `live` (Debian's default), live session only |
| This repository | Read-only copy in `/opt/emcomm-tools-os-community`, no git history; `install.sh` not executable |
| Accounts, SSH host keys, machine-id, logs | None; generated per install |

## Where things are

- `live-build/build.sh`: sets up and runs `lb config` / `lb build`.
- `live-build/config/package-lists/emcomm-tools.list.chroot`: base packages.
- `live-build/config/hooks/normal/0900-emcomm-tools.hook.chroot`: runs
  `install.sh` with `ET_BUILD=1`, adds et-api's NWS zone file, cleans up.
- `live-build/config/hooks/normal/0910-grub-pc-pool.hook.binary`: BIOS GRUB
  for offline installs.
- `live-build/config/includes.chroot/etc/calamares/`: installer settings.

## Publish

```bash
sha256sum emcomm-tools-os-community-<date>-amd64.hybrid.iso > emcomm-tools-os-community-<date>-amd64.hybrid.iso.sha256
```
