# Moving EmComm Tools from Ubuntu/Cubic to Debian/live-build

What changes, and why. For review only; remove this document once merged.
Building ISOs from now on: [ISO-BUILD-PLAN.md](ISO-BUILD-PLAN.md). Installing:
[docs/INSTALL-GUIDE.md](docs/INSTALL-GUIDE.md).

## Goals

1. **Move ETC from Ubuntu/Cubic to Debian 12/live-build.**
2. **Stay as close to r7's install process as possible:** users still run
   `install.sh` to install ETC and build their own ISO.
3. **Maintain r7's look, style and functionality.**
4. **Docs:** an ISO build guide, an end-user install guide and release notes.

## Key changes for the ETC developer

- **Build:** live-build replaces Cubic. `sudo ./build.sh` places users in the
  build's root shell to install ETC (`./install.sh`) and any extras; on `exit`,
  live-build builds the ISO.
- **Installer:** Calamares replaces Ubiquity, and is new for ETC to maintain:
  its settings are in `live-build/config/includes.chroot/etc/calamares/`, its
  branding and slideshow in `overlay/etc/calamares/branding/`.
- **Java:** OpenJDK 17 instead of 20, which Debian 12 doesn't have. ETC's Java
  apps need at most Java 11 (et-api) and 9 (YAAC); et-api runs on 17 in
  testing. Alternative: a non-Debian JDK 20+ (e.g. Eclipse Temurin) with its
  own updates.
- **VARA** under WINE 8.0 still needs testing. Debian 12 has WINE 8.0; r7 has
  7.0 (see [Version parity with r7](#version-parity-with-r7)).

## Improvements for users

- **Fewer tools to set up:** a minimal Debian 12 with git. No Cubic to install,
  and no `install-ubuntu-image-tools-only.sh` to maintain or run.
- **Nothing to type:** the release name, ISO file name, volume ID, boot menu
  and installer version all come from the newest ETC release tag. A build from
  newer commits also shows the commit, plus "modified" if there are
  uncommitted changes.
- **One command, no wizard:** no Cubic screens (packages, kernel,
  compression). The build runs on a machine without a desktop, or even over
  SSH.
- **Your checkout is the source:** no tarball to download inside the build and
  no scripts to patch by hand: edits to the repository's files go into the
  ISO.
- **Build summary:** `install.sh` ends with what to do next, and the build
  ends with the ISO's location and any failed `install.sh` steps, with the
  full log saved.

## Size/Scope

Branch `feature/debian-live-iso` against `release/r7` at build37
(`emcomm-tools-os-community-20261111-r7-build37`, merged in): **82 files,
+1,209 / −354 lines**, plus this document (97 lines).

It's less than it looks:

- 14 files are the install guide's screenshots, plus the guide itself
  (goal 4).
- 20 files are moves or deletions with no new logic: 9 renames (slideshow
  images, GNOME settings) and 11 deleted Ubuntu/Cubic files (goals 1–3).
- Edits to existing scripts are small: most are 1–10 lines; the largest is 41,
  `install-branding.sh` (goal 3). `install.sh` changes 10 lines.
- The main new code is the live-build and installer setup: 17 new files,
  +537 lines (goals 1–2).

It's planned as one PR with three commits, each reviewable on its own. The core
comes first; the others build on it in any order.

| # | Commit | Files | Lines | Share | Why |
|---|---|---|---|---|---|
| 1 | `Debian 12 base, live-build ISO and Calamares installer` | 30 | +560 / −148 | 46% | live-build replaces Cubic; users install ETC in the build's root shell<br>Release names come from the newest ETC release tag<br>Desktop: Debian's `gnome-core` plus r7's desktop apps<br>Small edits where scripts named specific Ubuntu packages, versions or URLs<br>Installer-created users get `et-data` as primary group<br>Read-only copy of this repository on the installed system (`/opt/emcomm-tools-os-community`) |
| 2 | `Look and feel parity with r7` | 35 | +349 / −206 | 29% | GNOME look (Yaru theme and top bar, dock, desktop and tray icons, window buttons)<br>Calamares slideshow ported from Ubiquity<br>ETC GRUB menus, background and boot splash (live ISO and installed)<br>Live session boots straight into the installer, launched with ETC's name and logo, without a password<br>Settings saved live carry into the install<br>SSH off in the live session |
| 3 | `ISO build guide, install guide, release notes` | 17 | +300 | 25% | Release notes<br>ISO build guide<br>This overview (counted separately; remove after the merge)<br>End-user install guide with screenshots |

## Version parity with r7

**Apps ETC downloads or builds itself keep r7's pinned versions.** Each
install script's `VERSION` is unchanged. Only SDR++ (nightly, unpinned in r7
too) now downloads the Debian build.

**New: JS8Call and WSJT-X are held** (`apt-mark hold`). Debian's
`js8call 2.2.0+ds` counts as newer than ETC's 2.2.0, so without the hold an
upgrade would replace ETC's build and conflict with its WSJT-X.

**Apps from the distribution's archive follow Debian 12.** These have no Debian
12 package at r7's version, so they can't be pinned to it:

| App | r7 (Ubuntu 22.10) | Debian 12 |
|---|---|---|
| WINE / winetricks | 7.0 / 20220411 | 8.0 / 20230212 |
| Thunderbird | 102 | 153 ESR |
| conky | 1.12 | 1.18 |
| Kiwix | 2.2 | 2.3 |
| Zim | 0.74 | 0.75 |
| osmium-tool | 1.14 | 1.15 |
| chrony | 4.2 | 4.3 |
| Python | 3.10 | 3.11 |
| Linux kernel | 5.19 | 6.1, with Debian's non-free firmware in the ISO |
