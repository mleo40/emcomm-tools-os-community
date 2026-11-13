# Moving EmComm Tools from Ubuntu/Cubic to Debian/live-build: what changes

What changes, and why. For review only; remove once merged. Building ISOs from
now on: [ISO-BUILD-PLAN.md](ISO-BUILD-PLAN.md).

## Goals

1. Move EmComm Tools from Ubuntu/Cubic to Debian/live-build.
2. Build one ISO suitable for distribution worldwide.
3. Let the person installing choose whether to install the encryption tools.
4. Boot, install and run with no internet.
5. Keep r7's application versions where possible (see
   [Version parity with r7](#version-parity-with-r7)).
6. Keep r7's look and style.

## For the ETC developer to review

The following describe changes that need the attention of the ETC Dev before
moving forward.

**New: the ISO is a live system.** It boots into a working GNOME
desktop with EmComm Tools, without installing anything. Installing to disk only
happens when the user clicks **Install EmComm Tools**.

**New: encryption tools are opt-in** (`install-crypto.sh`) and offered during
the user install now. The packages ship in the ISO but aren't
installed by default, unlike r7.

**Java version: OpenJDK 17 instead of 20.** r7 uses OpenJDK 20, which Debian
12 doesn't have. This branch uses Debian's OpenJDK 17 (Debian security
updates). ETC's Java apps need at most Java 11 (et-api) and Java 9 (YAAC), and
et-api runs on 17 in testing. The alternative is a non-Debian JDK 20+ (for
example Eclipse Temurin), with its own downloads and updates. Revisit if et-api
or YAAC ever needs Java 18 or later.

### Build-time choices

r7's build asked about these. The ISO build asks nothing, so a new process is
required:

| r7 question | Where | New experience |
|---|---|---|
| OSM state map (Navit) | `download-osm-maps.sh` | Not in the ISO. Run `download-osm-maps.sh` after install (needs internet) |
| ETC map tiles | `download-et-maps.sh` | World map (80 MB) in the ISO. Run `download-et-maps.sh` after install for US or Canada (needs internet) |
| Wikipedia file | `download-wikipedia.sh` | Kiwix installed, no `.zim` files. Run `download-wikipedia.sh` after install (needs internet) |
| VARA/WINE notes | `install-wine.sh`, `wine.txt` | WINE and the VARA add-on scripts (`~/add-ons/wine`) are in the ISO; installing VARA is optional, after install, and needs internet |
| xara modem | `install-xara.sh`, `scripts/xara.md` | Build tools (Rust) and `install-xara.sh` are in the ISO; installing xara is optional, after install, from the user's own `xara-*.tar.gz`, and needs internet |

## Version parity with r7

**Apps ETC downloads or builds itself keep r7's pinned versions.** Each
install script's `VERSION` is unchanged. Only SDR++ (nightly, unpinned in r7
too) now downloads the Debian build.

**New: JS8Call and WSJT-X are held** (`apt-mark hold`). Debian's
`js8call 2.2.0+ds` counts as newer than ETC's 2.2.0, so without the hold an
upgrade would replace ETC's build and conflict with its WSJT-X. r7 had no holds.

**Desktop apps match r7's Ubuntu desktop.** Debian's `gnome-core` plus r7's
desktop apps, not Debian's full GNOME.

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
| USB stick writer | USB Creator 0.3.15 (Ubuntu-only) | mintstick 1.5.5 (USB Image Writer and Stick Formatter) |

VARA under WINE 8.0 still needs testing.

## Size/Scope of this migration

Branch `feature/debian-live-iso` against `release/r7` at build37
(`emcomm-tools-os-community-20261111-r7-build37`, merged in): **96 files,
+1,283 / −380 lines** (not counting this document).

It's less than it looks:

- 17 files are the install guide's screenshots, plus the guide itself.
- 22 files are moves or deletions with no new logic: 11 renames (slideshow
  images, encryption guide files) and 11 deleted
  Ubuntu/Cubic files.
- Most edits to existing scripts are 1–10 lines.
- It's planned as one PR with five commits, each reviewable on its own. The
  core comes first; the others build on it in any order. Estimated sizes
  against r7:

| Commit | Files | Lines | Share | Why |
|---|---|---|---|---|
| 1. Core: Debian 12, live-build ISO, Calamares installer | 42 | +602 / −166 | 47% | Ubuntu's installer and Cubic don't exist on Debian. live-build replaces Cubic's manual steps with code: all new files. Each script that named an Ubuntu package, version or URL gets a small edit. `install.sh` asks nothing during the build. Users created by the installer get ETC's `et-data` group as primary. |
| 2. Desktop and boot parity with r7 | 16 | +159 / −200 | 12% | Ubuntu builds in its dock, theme, tray icons and boot branding; Debian needs them added. Calamares gets r7's slideshow. |
| 3. Encryption tools opt-in | 13 | +174 / −14 | 14% | Distribution requirement, not Debian's. An installer page lets users choose; the guides are moved unchanged, so only users who choose the tools get them. |
| 4. Live-session polish | 5 | +107 | 8% | The installer launcher has ETC's name and logo and starts without a password; settings saved in the live session carry into the install. |
| 5. Docs | 20 | +239 | 19% | Release notes, developer build guide, end-user install guide. |

## Additions beyond the Debian port

Changes beyond the Debian port itself, and why each is in. Together they're
over a third of the added lines:

| Commit | Change | Why it's here |
|---|---|---|
| 1 | `build.sh` keeps live-build's download cache | Faster ISO rebuilds (not strictly necessary) |
| 1 | Read-only repository copy in `/opt/emcomm-tools-os-community` | Needed to add the encryption tools or xara after install; also ETC's test suite. r7 left its copy in `/root`, out of users' reach |
| 2 | GNOME parity: Yaru theme (including the top bar), dock, desktop icons, tray icons, window buttons | Branding parity with r7 |
| 2 | Calamares slideshow ported from Ubiquity (`show.qml`, `EtcSlide.qml`) | Branding parity with r7 |
| 2 | GRUB menus branded: ETC background on the live ISO's boot menu; "EmComm Tools" and the same background on installed systems | Branding parity with r7 |
| 2 | ETC boot splash watermark: Debian's logo diverted (Debian's plymouth puts its own in) | Branding parity with r7 |
| 3 | Installer stylesheet (`stylesheet.qss`): the encryption choices drawn as buttons | Encryption is legally restricted in some jurisdictions, so installing the tools must be a clear, deliberate choice |
| 4 | Live-session polish: ETC installer launcher and dock; live settings carried into the install | Branding parity with r7 and usability of the live session |
| 5 | End-user install guide with screenshots ([INSTALL-GUIDE.md](docs/INSTALL-GUIDE.md)) | The installer and boot steps changed from r7 |
