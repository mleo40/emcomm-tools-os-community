# Plan: official EmComm Tools ISO with live-build

Branch `feature/debian-live-iso`, from `release/r7`.

One Debian 12 + EmComm Tools ISO, built and published by the ETC developer.
Users boot it live and install it with Calamares. No build options for users,
no operator data in the ISO.

## Build (developer)

Needs: a Debian 12 build machine (VM is fine), about 60 GB free, internet,
root. Packages: `live-build`, `git`.

```bash
git clone -b feature/debian-live-iso https://github.com/mleo40/emcomm-tools-os-community.git
cd emcomm-tools-os-community/live-build
sudo ./build.sh
```

`build.sh` runs `lb config` and `lb build`:

1. Debian 12 chroot with GNOME, Calamares and the packages in
   `config/package-lists/`.
2. Chroot hook `9000-emcomm-tools.hook.chroot` copies the repo into the chroot
   and runs `install.sh` with `ET_BUILD=1` (no prompts), then removes the copy.
3. Binary stage: hybrid ISO (USB or DVD, BIOS or UEFI) with Debian's signed
   shim and GRUB, so it boots with Secure Boot on.

The build never has a user logged in, so there's no operator data to strip.

## install.sh build mode (`ET_BUILD=1`)

| Step | Normal | Build mode |
|---|---|---|
| OSM state map, ETC map country | asked | skipped; maps are chosen at first login |
| Global map (80 MB) | if chosen | always, into `/etc/skel` |
| Encryption tools | asked | staged, plus their `.deb`s, for the installer page |
| Existing-user setup | runs | skipped (no user) |
| Release name | from git tag | from git tag, or `ET_RELEASE` |

## Installer (Calamares)

- Debian's `calamares-settings-debian`, with ETC's `emcomm-tools` branding and
  slideshow.
- **Optional software** page (`packagechooser`): "Encryption tools",
  unchecked. If ticked, `install-crypto.sh --offline` installs them into the
  new system from the `.deb`s carried in the ISO. No internet needed.
- Users created by Calamares get `et-data` as primary group and the
  `adduser.conf` extra groups (a `shellprocess` step).
- The full-disk encryption checkbox stays visible and unchecked.

## First login (each operator)

1. ETC user setup (callsign, grid, Winlink), as today.
2. New map step: country tiles (US, Canada) and a US state for Navit, or
   skip. Saved in that operator's home, as today. A "Download maps" launcher
   runs it again later.

## Live session

Debian's defaults: user `user`, password `live`. live-config creates this user
at boot, so it isn't in the installed system. `build.sh` adds it to ETC's
groups (`dialout`, `et-data` and the rest).

## Order of work

1. `install.sh` build mode.
2. live-build config and Calamares settings; first build; boot-test with
   Secure Boot on.
3. Optional software page and offline crypto install.
4. First-login map step.
5. Hardware test with a radio.
