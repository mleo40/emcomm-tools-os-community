# Moving EmComm Tools from Ubuntu/Cubic to Debian/live-build

What changes, and why. For review only; remove once merged. Building ISOs from
now on: [ISO-BUILD-PLAN.md](ISO-BUILD-PLAN.md).

## Goals

1. **Move ETC to Debian 12 and live-build**, keeping r7's app versions (see
   [Version parity with r7](#version-parity-with-r7)) and working with no
   internet.
2. **Keep r7's look and style.**
3. **One ISO for worldwide distribution:** the person installing chooses
   whether to install the encryption tools.
4. **A usable live session** whose settings carry into the install.
5. **Docs** for whoever builds the ISO and whoever installs it.

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
| OSM state map (Navit) | `download-osm-maps.sh` | Navit is in the ISO; the state map files aren't. Run `download-osm-maps.sh` after install (needs internet) |
| ETC map tiles | `download-et-maps.sh` | World map (80 MB) in the ISO. Run `download-et-maps.sh` after install for US or Canada (needs internet) |
| Wikipedia file | `download-wikipedia.sh` | Kiwix installed, no `.zim` files. Run `download-wikipedia.sh` after install (needs internet) |
| VARA/WINE notes | `install-wine.sh`, `wine.txt` | WINE and the VARA add-on scripts (`~/add-ons/wine`) are in the ISO; installing VARA is optional, after install, and needs internet |
| xara modem | `install-xara.sh`, `scripts/xara.md` | Build tools (Rust) and `install-xara.sh` are in the ISO; installing xara is optional, after install, from a user-supplied `xara-*.tar.gz`, and needs internet |

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
(`emcomm-tools-os-community-20261111-r7-build37`, merged in): **97 files,
+1,288 / −380 lines** (not counting this document).

It's less than it looks:

- 17 files are the install guide's screenshots, plus the guide itself.
- 22 files are moves or deletions with no new logic: 11 renames (slideshow
  images, encryption guide files) and 11 deleted
  Ubuntu/Cubic files.
- Most edits to existing scripts are 1–10 lines.
- It's planned as one PR with five commits, each reviewable on its own. The
  core comes first; the others build on it in any order. Estimated sizes
  against r7:

| # | Commit | Files | Lines | Share | Why |
|---|---|---|---|---|---|
| 1 | `Debian 12 base, live-build ISO and Calamares installer` | 42 | +602 / −166 | 47% | live-build replaces Cubic's manual steps (all new files)<br>Small edits where scripts named Ubuntu packages, versions or URLs<br>`install.sh` asks nothing during the build<br>Installer-created users get `et-data` as primary group<br>Read-only repo copy in `/opt/emcomm-tools-os-community`: users can add the encryption tools or xara later and run ETC's test suite (r7's copy sat in `/root`, out of reach)<br>`build.sh` keeps live-build's download cache for faster rebuilds (optional) |
| 2 | `Desktop and boot branding parity with r7` | 16 | +159 / −200 | 12% | Branding parity: GNOME look (Yaru theme and top bar, dock, desktop and tray icons, window buttons)<br>Calamares slideshow ported from Ubiquity<br>ETC GRUB menus and background (live ISO and installed)<br>ETC boot splash<br>Ubuntu builds these in; Debian needs them added |
| 3 | `Encryption tools opt-in at install` | 13 | +174 / −14 | 14% | Distribution requirement: encryption is legally restricted in some jurisdictions, so installing the tools must be a deliberate choice the user makes<br>Installer page with Skip/Install buttons (`stylesheet.qss`)<br>Guides move unchanged, so only users who choose the tools get them |
| 4 | `Live-session polish` | 6 | +112 | 9% | Branding parity and live-session usability<br>Installer launcher with ETC's name and logo, starting without a password<br>ETC's dock<br>Settings saved live carry into the install<br>SSH off in the live session (public login) |
| 5 | `docs - ISO build guide, install guide, release notes` | 20 | +239 | 19% | Release notes<br>ISO build guide (`ISO-BUILD-PLAN.md`)<br>End-user install guide with screenshots (installer and boot steps changed from r7) |

<br><br><br><br><br><br>
