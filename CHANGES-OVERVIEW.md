# Moving EmComm Tools from Ubuntu/Cubic to Debian/live-build

What changes, and why. For review only; remove this document once merged.
Building ISOs from now on: [ISO-BUILD-PLAN.md](ISO-BUILD-PLAN.md).

## Goals

1. **Move ETC from Ubuntu/Cubic to Debian 12/live-build.**
2. **Stay as close to r7 as possible:** the same build steps, look, style and
   functionality. Users build their own ISO, as with r7.
3. **Docs:** an ISO build guide and an end-user install guide.

## Key changes for the ETC developer

- **Build:** live-build replaces Cubic, with the same steps. `sudo ./build.sh`
  places you in a shell to install ETC (`./install.sh`, r7's questions) and any
  extras; on `exit`, live-build builds the ISO.
- **Installer:** Calamares replaces Ubiquity; r7's slideshow is ported.
- **Java:** OpenJDK 17 instead of 20, which Debian 12 doesn't have. ETC's Java
  apps need at most Java 11 (et-api) and 9 (YAAC); et-api runs on 17 in
  testing. Alternative: a non-Debian JDK 20+ (e.g. Eclipse Temurin) with its
  own updates.
- **VARA** under WINE 8.0 still needs testing. Debian 12 has WINE 8.0; r7 has
  7.0 (see [Version parity with r7](#version-parity-with-r7)).

## Size/Scope

Branch `feature/debian-live-iso` against `release/r7` at build37
(`emcomm-tools-os-community-20261111-r7-build37`, merged in): **82 files,
+1,152 / −354 lines**, plus this document (76 lines).

It's less than it looks:

- 14 files are the install guide's screenshots, plus the guide itself
  (goal 3).
- 20 files are moves or deletions with no new logic: 9 renames (slideshow
  images, GNOME settings) and 11 deleted Ubuntu/Cubic files (goals 1–2).
- Edits to existing scripts are small: most are 1–10 lines; the largest is 41,
  `install-branding.sh` (goal 2). `install.sh` changes 5 lines.
- The main new code is the live-build and installer setup: 17 new files,
  +537 lines (goal 1).

It's planned as one PR with four commits, each reviewable on its own. The core
comes first; the others build on it in any order.

| # | Commit | Files | Lines | Share | Why |
|---|---|---|---|---|---|
| 1 | `Debian 12 base, live-build ISO and Calamares installer` | 30 | +555 / −148 | 48% | live-build replaces Cubic, with the same steps: the build pauses in a root shell for `install.sh`<br>Desktop: Debian's `gnome-core` plus r7's desktop apps<br>Small edits where scripts named specific Ubuntu packages, versions or URLs<br>Installer-created users get `et-data` as primary group<br>Read-only copy of this repository on the installed system (`/opt/emcomm-tools-os-community`) |
| 2 | `Desktop and boot branding parity with r7` | 28 | +232 / −206 | 20% | GNOME look (Yaru theme and top bar, dock, desktop and tray icons, window buttons)<br>Calamares slideshow ported from Ubiquity<br>ETC GRUB menus, background and boot splash (live ISO and installed) |
| 3 | `Live-session polish` | 7 | +117 | 10% | Boots straight into the installer<br>Installer launcher with ETC's name and logo, starting without a password<br>Settings saved live carry into the install<br>SSH off in the live session |
| 4 | `ISO build guide, install guide, release notes` | 17 | +248 | 22% | Release notes<br>ISO build guide<br>This overview (counted separately; remove after the merge)<br>End-user install guide with screenshots |

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
