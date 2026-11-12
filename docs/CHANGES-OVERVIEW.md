# Moving EmComm Tools from Ubuntu/Cubic to Debian/live-build: what changes

This document covers what one-time changes are needed to move EmComm Tools from Ubuntu/Cubic to Debian/live-build,
and why.

Once these changes are PR/merged, this document becomes irrelevant and can be removed.

How to build ISOs from now on is in
[ISO-BUILD-PLAN.md](../ISO-BUILD-PLAN.md) and should persist.

## Goal

The smallest change that:

1. moves EmComm Tools from Ubuntu/Cubic to Debian/live-build,
2. builds an ISO for global distribution,
3. leaves the encryption tools installation up to the person installing, and
4. produces an ISO that boots, installs and runs with no internet. Installing
   VARA (optional) needs internet, or a WINE backup to restore.

## For the ETC developer to review

The following describe changes that need decisions from the ETC Dev before moving forward

### Changes in the user experience

r7's install process asked the ISO builder certain questions. The new ISO build
asks none, so each is handled differently now:

| r7 question | Where | Now |
|---|---|---|
| OSM state map (Navit) | `download-osm-maps.sh` | Not in the ISO. Planned: first-login map step per operator. Until then there's no simple way to get it |
| ETC map tiles: US, Canada or world | `download-et-maps.sh` | The world map (80 MB) is in the ISO. US and Canada tiles: same planned first-login step |
| Wikipedia file (`ET_EXPERT`) | `download-wikipedia.sh` | No `.zim` files ship with the ISO; the Kiwix reader is installed. Users download `.zim` files after install ([INSTALL-GUIDE.md](INSTALL-GUIDE.md)) |
| VARA/WINE notes (`ET_EXPERT`) | `install-wine.sh`, `wine.txt` | WINE, winetricks and the VARA add-on scripts (`~/add-ons/wine`) are in the ISO; VARA itself isn't. Users install it after install, with internet or by restoring a WINE backup made with `05-backup-wine-install.sh` (`cd ~ && tar -xzf etc-wine-backup-*.tar.gz`). Covered in [INSTALL-GUIDE.md](INSTALL-GUIDE.md) |

Other changes users will notice:

| Change | Effect |
|---|---|
| xara | Upstream source was withdrawn; built only if `scripts/xara-*.tar.gz` is provided. Deferred to the next release |
| Encryption tools | Always installed in r7. Now asked by the installer's **Optional software** page; not selected by default. The page (and `install.sh`'s prompt) says not to install them where encryption is illegal |
| Installer | This is a Live CD ISO image and will boot into a working GNOME desktop.  Decision to install requires clicking the button

### Java version

r7 uses OpenJDK 20, which Debian 12 doesn't have. This branch uses Debian's
OpenJDK 17 (Debian security updates). ETC's Java apps need at most Java 11
(et-api) and Java 9 (YAAC), and et-api runs on 17 in testing. The alternative
is a non-Debian JDK 20+ (for example Eclipse Temurin), with its own downloads
and updates. Revisit if et-api or YAAC ever needs Java 18 or later.

## Version parity with r7

**Applications ETC downloads or builds itself keep r7's pinned versions.** The
`VERSION` in each install script is unchanged, for example JS8Call 2.2.0, WSJT-X
2.7.0, fldigi 4.2.09, flmsg 4.0.24, flamp 2.2.14, Hamlib 4.5, Direwolf 1.7, Pat
1.0.0, Mercury 1.9.22, Reticulum 1.6.0 and et-api 1.3.0. Only two download
names changed, to the Debian build of the same release: VeraCrypt 1.26.29 and
SDR++ (nightly, unpinned in r7 too). Apps built from source install to
`/usr/local`, outside apt's reach.

**New: JS8Call and WSJT-X are held** (`apt-mark hold`). Debian's archive has
`js8call 2.2.0+ds`, which apt treats as newer than ETC's 2.2.0 and would install
on upgrade, replacing ETC's build and conflicting with its WSJT-X. r7 had no
holds. None of ETC's other `.deb`s have a newer version in Debian's archive.

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

All other user-facing archive apps (Audacity, VLC, QGIS, gpsd, GPSBabel,
Navit, minimodem, sox, SPLAT!, espeak, dict, ax25-apps) are the same major and
minor version. Checked 11 Nov 2026 against Ubuntu 22.10's package index and a
Debian 12 install. To watch in hardware testing: VARA under WINE 8.0.

## Size/Scope of this migration

Branch `feature/debian-live-iso` against `release/r7`: **76 files,
+1,674 / −341 lines** (not counting this document).

It's less than it looks:

- 22 files are moves or deletions with no new logic: 12 renames (slideshow
  images, encryption guide files, the GNOME settings file) and 10 deleted
  Ubuntu/Cubic files.
- Most edits to existing scripts are 1–10 lines.
- The branch combines three separate efforts: the Debian port, the new ISO
  build, and the encryption tools opt-in.

## By category

| # | Category | Files | Lines +/− | Why |
|---|---|---|---|---|
| 1 | Installer: Ubiquity → Calamares | 22 | +312 / −209 | Ubuntu's installer doesn't exist on Debian. The 8 slideshow images only moved. The 9 Ubiquity HTML slides were deleted, and the same 8 slides were ported to one Calamares `show.qml` (264 lines). |
| 2 | New ISO build (live-build) | 15 | +545 | Replaces Cubic. All new files; nothing existing changed. |
| 3 | Encryption tools opt-in | 11 | +221 / −23 | Product requirement, not Debian's. `install-crypto.sh` is most of it. The guide files (`gpg-cheatsheet.md`, `steghide.md`, `steghide.jpg`) were moved unchanged, so only users who choose the tools get them. |
| 4 | Debian package and OS differences | 16 | +115 / −74 | A small edit in each script that named an Ubuntu package, version or URL. |
| 5 | Desktop parity with r7 | 6 | +77 / −20 | Ubuntu builds in its dock, theme and tray icons; Debian needs them added. No automatic update checks, as in r7. |
| 6 | Users | 2 | +92 | Users created by the installer get ETC's `et-data` group as primary. |
| 7 | Build mode | 2 | +53 / −15 | `install.sh` asks nothing during the image build. |
| 8 | Docs | 2 | +259 | Release notes; end-user install guide. |

## Beyond the minimum

Changes the goal didn't strictly need, and why they're in. Together they're
roughly a third of the added lines; dropping them gives the smallest possible
migration, at the cost of r7's look and some live-session usability:

| Change | Why it's here | Could drop? |
|---|---|---|
| GNOME parity: Yaru theme, dock, desktop icons, tray icons, window buttons | Look and version parity with r7 | Yes, if r7's look isn't required |
| Calamares slideshow ported from Ubiquity (`show.qml`) | Branding parity | Yes; Calamares works without it |
| GRUB menus branded: ETC background on the live ISO's boot menu; "EmComm Tools" and the same background on installed systems | Branding parity | Yes; the stock Debian menus work |
| `configure-existing-user.sh` | Only for running `install.sh` on an existing Debian system; the ISO doesn't use it | Yes, if only the ISO is supported |
| Live-session polish: installer icon shown correctly, installer starts without a password, ETC dock in the live session, callsign/grid/Winlink password saved in the live session carried into the installed system | Usability of the live session | Yes; the ISO works without them |
| Update checks off: GNOME Software settings and login service, apt's daily timers | r7 removed Ubuntu's update-notifier; an offline system shouldn't try | No (requested) |
| `et-fix-primary-group` (installer step) | ETC shares files through the `et-data` group, and Calamares can't set a primary group | Only by changing ETC's group design |
| ETC boot splash watermark: Debian's logo diverted (Debian's plymouth puts its own in) | Branding parity | Yes; Debian's logo shows instead |
| `configure-user.sh` doesn't fail if `et-data` exists | Lets `install.sh` run twice on the same system | Yes; the ISO build runs it once |
| `build.sh` keeps live-build's download cache | Faster rebuilds | Yes |
| End-user install guide with screenshots ([INSTALL-GUIDE.md](INSTALL-GUIDE.md)): Ventoy stick with a folder for maps, `.zim` files and VARA backups; booting; installing; copying those files in after install | The installer and boot steps changed from r7; users need current instructions | Yes; it's documentation only |

## Verified (11–12 Nov 2026)

In VMs, with the network unplugged unless noted:

| Test | Result |
|---|---|
| Build (`live-build/build.sh`) | Completes; `install.sh` 0 failed steps |
| ISO contents | No build files, logs, SSH host keys or machine-id; encryption tools prepared, not installed; WINE (32- and 64-bit), winetricks and the VARA add-on scripts included |
| UEFI, Secure Boot on: live session | ETC boot menu, splash, desktop and dock; installer starts without a password; Optional software page text; slideshow advances |
| UEFI, Secure Boot on: install with encryption tools | Tools and guides installed from the ISO |
| UEFI, Secure Boot on: install without encryption tools | No tools, guides or marker; add-on still available |
| UEFI, Secure Boot on: installed system | Boots; ETC splash, dock, wallpaper; `et-data` primary group; SSH server running; apt sources include `contrib` and `non-free`; update checks off; ETC test suite passes except xara (no source package) |
| BIOS (no UEFI): live boot and install | Boots and installs; BIOS GRUB installed from the ISO |
| Ventoy 1.1.10, UEFI, Secure Boot off | ISO boots from a Ventoy stick to the ETC boot menu and live desktop |

Not tested yet: the encryption legal notice in the installer (added after the
last build), the installed system's GRUB branding, Ventoy with Secure Boot on,
and hardware with a radio (CAT, audio, JS8Call, WSJT-X, VARA under WINE).

## Files in each category

### 1. Installer: Ubiquity → Calamares

| File | Change |
|---|---|
| `overlay/usr/share/ubiquity-slideshow/slides/*.html` (9) | Deleted |
| `overlay/usr/share/ubiquity/pixmaps/ubuntu_installed.png` | Deleted |
| `overlay/etc/calamares/branding/emcomm-tools/screenshots/*.png` (7), `background.png` | Moved from the Ubiquity slideshow, unchanged |
| `overlay/etc/calamares/branding/emcomm-tools/show.qml` | New: the same 8 slides, as Calamares QML |
| `overlay/etc/calamares/branding/emcomm-tools/branding.desc`, `logo.png` | New: installer name and logo |
| `scripts/debrand.sh` | Installs the Calamares branding instead of Ubiquity's; drops the Cubic kernel reinstall |

### 2. New ISO build (live-build)

| File | Purpose |
|---|---|
| `live-build/build.sh` | The one build command |
| `live-build/config/hooks/normal/0900-emcomm-tools.hook.chroot` | Runs `install.sh` inside the image (before Debian's cleanup hooks); removes build files; ETC launchers in the live dock |
| `live-build/config/hooks/normal/0910-grub-pc-pool.hook.binary` | Adds BIOS GRUB to the ISO's package pool (it conflicts with UEFI GRUB, so it can't go in the package list) |
| `live-build/config/package-lists/emcomm-tools.list.chroot` | GNOME and Calamares in the image |
| `live-build/config/package-lists/installer.list.binary` | GRUB packages carried in the ISO, so installs work offline |
| `live-build/config/includes.chroot/etc/calamares/settings.conf` | Installer steps (Debian's, plus ETC's five) |
| `live-build/config/includes.chroot/etc/calamares/modules/*.conf` (6) | Groups for new users, Optional software page, offline encryption install, ETC setup (primary group, SSH host keys), live settings carry-over, apt sources (Debian's installer drops `contrib` and `non-free`; this puts them back) |
| `live-build/config/includes.chroot/usr/local/sbin/et-carry-live-settings` | Copies the callsign, grid and Winlink password saved in the live session to the new user |
| `live-build/config/includes.chroot/…/et-trust-live-installer` (2) | Live session: shows the installer icon as trusted on GNOME |
| `live-build/config/includes.chroot/usr/lib/live/config/2500-etc-installer-polkit` | Live session: the installer starts without a password |
| `ISO-BUILD-PLAN.md` | Developer guide: building and publishing ISOs |

### 3. Encryption tools opt-in

| File | Change |
|---|---|
| `scripts/install-crypto.sh` | New: installs GPA, PFTE, VeraCrypt, steghide, gpg and guides; or prepares them for the installer and installs them offline |
| `scripts/crypto-docs/gpg-cheatsheet.md`, `steghide.md`, `steghide.jpg` | Moved unchanged from `overlay/etc/skel/Desktop/offline/crypto/` (which every user got), so they're only installed with the tools |
| `scripts/install-offline-lib-crypto.json`, `install-offline-lib.json` | AmRRON key and GPG guide moved to the crypto list |
| `scripts/install-offline-lib.sh` | Takes a file list and destination |
| `scripts/install-pfte.sh`, `install-veracrypt.sh` | Download-only mode, for the offline install |
| `tests/test-gpa.sh`, `test-pfte.sh` | Pass when the tools weren't chosen |

### 4. Debian package and OS differences

| File | Change |
|---|---|
| `overlay/etc/apt/sources.list` | Debian 12 sources |
| `overlay/etc/crontab` | Remove the Cubic-only `@reboot` copy |
| `overlay/etc/profile.d/emcomm-tools.sh` | New: `PATH` for ETC commands (Debian's `/etc/profile` resets it) |
| `scripts/install-base.sh` | OpenJDK 20 → 17 (Debian 12 has no 20); `gpg` and `steghide` moved to the encryption add-on |
| `scripts/install-python.sh` | Python 2 removed (not in Debian 12) |
| `scripts/install-wsjtx.sh`, `install-sdrpp.sh` | Debian package names and Debian build |
| `scripts/install-js8call.sh`, `install-wsjtx.sh` | Hold ETC's builds; Debian's newer-looking `js8call` would replace them and conflict with ETC's WSJT-X |
| `scripts/remove-packages.sh` | Remove Debian's extra apps and first-login wizard; keep GNOME; disable apt's daily update timers |
| `scripts/install-dev-tools.sh` | Cubic PPA removed |
| `scripts/install-ubuntu-image-tools-only.sh` | Deleted (Cubic tooling) |
| `scripts/install-release.sh`, `overlay/opt/emcomm-tools/bin/et-system-info` | Release name; Cubic wrote it to `/etc/lsb-release` |
| `scripts/configure-user.sh` | Don't fail if `et-data` already exists |
| `tests/test-java.sh`, `test-python.sh` | Expect Java 17 and Python 3 |

### 5. Desktop parity with r7

| File | Change |
|---|---|
| `overlay/usr/share/glib-2.0/schemas/90_emcomm-tools.gschema.override` | Renamed from `90_ubuntu-settings`; dock, extensions, window buttons, dark-style wallpaper, update notifications off |
| `scripts/configure-gnome.sh` | Install Yaru theme and the dock, desktop-icon and tray-icon extensions |
| `scripts/install-branding.sh` | Boot splash and wallpaper on Debian; ETC watermark instead of Debian's logo (Debian's plymouth swaps it in); GRUB menu name and background |
| `logos/emcomm-tools-boot-800x600.png`, `-640x480.png` | New: GRUB menu background for the live ISO (via `live-build/build.sh`) and installed systems |
| `overlay/etc/skel/.config/autostart/org.gnome.Software.desktop` | New: GNOME Software's update service doesn't start at login (the app still opens) |

### 6. Users

| File | Change |
|---|---|
| `overlay/opt/emcomm-tools/bin/et-fix-primary-group` | New: `et-data` as primary group for users the installer creates |
| `scripts/configure-existing-user.sh` | New: sets up the user when `install.sh` runs on an existing Debian system (not used by the ISO) |

### 7. Build mode

| File | Change |
|---|---|
| `scripts/install.sh` | `ET_BUILD=1`: no prompts; maps chosen at first login; encryption tools prepared, not asked |
| `scripts/download-et-maps.sh` | Country can be passed instead of asked |

### 8. Docs

| File | Change |
|---|---|
| `RELEASES.md` | Release entry |
| `docs/INSTALL-GUIDE.md`, `docs/install-guide/images/` | New: end-user guide (Ventoy USB stick with room for maps, `.zim` files and VARA backups; installing; after install) |

The developer build guide is `ISO-BUILD-PLAN.md` (category 2).
