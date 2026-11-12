# Building EmComm Tools ISO images

How the ETC developer builds an EmComm Tools ISO for distribution. The ISO is
Debian 12 with EmComm Tools installed, built with Debian/live-build. Users boot it, try it live,
and install it with the installer (Calamares). Building the image needs internet; the
finished ISO boots, installs and runs without it.

Why the project moved to this method, and what changed to get here, is in
[CHANGES-OVERVIEW.md](CHANGES-OVERVIEW.md).

## What you need

- A Debian 12 machine to build on. A VM is fine: 4 CPUs, 6 GB RAM, 100 GB disk.
- About 60 GB free, internet, and root (`sudo`).
- `git` 
- `build.sh` (from this repo) installs `live-build` if it's missing.

The build happens in a fresh, separate system (a chroot), so nothing from the
build machine's accounts, files or settings ends up in the ISO. A
general-purpose machine is fine, but don't build on a machine whose packages
you've changed by hand.

## Build

```bash
git clone https://github.com/thetechprepper/emcomm-tools-os-community.git
cd emcomm-tools-os-community
git checkout <release tag or branch>
cd live-build
sudo ./build.sh
```

Build from a clean checkout. `build.sh` copies only files git tracks, and
warns if tracked files have uncommitted changes, because those go into the
ISO.

It takes about 45 minutes, mostly `install.sh` compiling and downloading. The
ISO and `build.log` are written to `/var/tmp/etc-live-build/`:

```
emcomm-tools-os-community-<date>-amd64.hybrid.iso    about 4.9 GB
```

At the end, `build.sh` prints the `install.sh` summary from the build:

```
=== EmComm Tools build: install.sh exit code 0 ===
=== Failed steps: 0 ===
```

Any failed step is listed underneath. Check them in `build.log` before
publishing.

## Build options

| Option | How | Default |
|---|---|---|
| Release name (shown in the conky panel, sent as JS8Call's MyInfo) | `sudo ET_RELEASE=ETC-r8-debian12 ./build.sh` | From the last ETC tag, e.g. `ETC-r7-build37-debian12` |
| Build folder | `sudo ET_WORK_DIR=/path ./build.sh` | `/var/tmp/etc-live-build` (emptied at the start of each build; the download cache is kept) |

To change what's in the image beyond these, edit the repository, the same as
for any ETC change: `scripts/install.sh` and its scripts, `overlay/`, or
`live-build/config/package-lists/`.

The `ET_EXPERT` offline Wikipedia download isn't available in an ISO build:
it asks which file to download, and the build runs without prompts.

## What's in the ISO

| Item | In the ISO |
|---|---|
| Debian 12, GNOME, EmComm Tools | Installed |
| Maps | The global map (80 MB). How users add other maps after install is still to be decided (see [CHANGES-OVERVIEW.md](CHANGES-OVERVIEW.md)) |
| Encryption tools (GPA, PFTE, VeraCrypt, steghide, gpg, guides) | Carried, not installed. The person installing chooses them on the installer's **Optional software** page (not selected by default); they install from the ISO, no internet needed. They can also be added later from `/opt/emcomm-tools/add-ons/crypto` |
| GRUB for UEFI and BIOS | Carried, so installs work offline |
| xara modem | Not included (its source was withdrawn; a `xara-*.tar.gz` in `scripts/` isn't copied). Rust is installed. How users add xara after install is still to be decided (see [CHANGES-OVERVIEW.md](CHANGES-OVERVIEW.md)) |
| Live session login | Debian's defaults: user `user`, password `live`. Only in the live session; installed systems have only the account created in the installer |
| This repository | A read-only copy in `/opt/emcomm-tools-os-community` (about 10 MB, no git history): ETC's scripts and test suite, matching the ISO |
| Accounts, home folders, SSH host keys, machine-id, logs, build files | None. Each installed system gets its own SSH host keys and machine-id |

## How the build works

1. `build.sh` copies the repository into live-build's config and runs
   `lb config` and `lb build`.
2. live-build creates a Debian 12 chroot with the packages in
   `live-build/config/package-lists/emcomm-tools.list.chroot`.
3. The `0900-emcomm-tools` chroot hook runs `install.sh` with `ET_BUILD=1`:
   no prompts, no maps beyond the global map, encryption tools prepared but not
   installed, no existing user to set up. It then downloads et-api's NWS
   forecast zone file (pinned, checksum checked) to
   `/opt/emcomm-tools-api/data/weather-forecast-zone.csv`: et-api 1.3.0 needs
   it but its release doesn't include it (see
   [CHANGES-OVERVIEW.md](CHANGES-OVERVIEW.md)); if the download fails, it
   counts as a failed step. It keeps a read-only copy of
   the repository (tracked files, no git history) in
   `/opt/emcomm-tools-os-community`, and removes the build copy and the
   build's downloads. live-build's own cleanup hooks run after it and remove
   logs, SSH host keys and machine-id.
4. The binary stage adds Debian's signed shim and GRUB (Secure Boot), the GRUB
   packages the installer needs (the `0910-grub-pc-pool` hook adds BIOS GRUB),
   and writes the hybrid ISO (USB or DVD, BIOS or UEFI).

The installer settings are in
`live-build/config/includes.chroot/etc/calamares/`: Debian's settings with
ETC's branding, the Optional software page, and ETC steps that give new users
`et-data` as primary group, create SSH host keys, carry over the callsign and
grid saved in the live session, and restore `contrib`/`non-free` in apt
sources.

## Test before publishing

In a VM with UEFI and Secure Boot on, and with no network:

1. The ISO boots to the live desktop: ETC wallpaper, dock, conky panel and boot
   splash.
2. **Install EmComm Tools** starts the installer without a password.
3. Install once with **Install encryption tools** selected and once without. In one
   of them, save a callsign and grid in the live session's EmComm Tools User
   Configuration first.
4. The installed system boots with Secure Boot on, and its boot menu shows
   "EmComm Tools GNU/Linux" with the ETC background. Log in, then check:
   - ETC's first-login setup opens, except after the install where a callsign
     was saved live: then it doesn't, and `~/.config/emcomm-tools/user.json`
     has that callsign and grid
   - `id` shows `et-data` as the primary group
   - `systemctl is-active ssh` is `active`
   - the encryption tools are there only if they were selected
5. As the installed user, run the install check, which also runs ETC's app
   tests: `/opt/emcomm-tools-os-community/tests/validate-install.sh`. It
   reports PASS, FAIL, WARN and SKIP for each check and exits with the number
   of failures. Plug in the radio audio interface and GPS first to include
   them.

Also boot it once on a BIOS (non-UEFI) machine or VM.

## Publish

```bash
sha256sum emcomm-tools-os-community-<date>-amd64.hybrid.iso > emcomm-tools-os-community-<date>-amd64.hybrid.iso.sha256
```

Publish the ISO with its `.sha256` file, and point users to
[docs/INSTALL-GUIDE.md](docs/INSTALL-GUIDE.md): it covers checking the
download, a Ventoy USB stick, the live system and installing.
