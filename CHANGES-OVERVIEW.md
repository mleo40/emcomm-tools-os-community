# Moving EmComm Tools from Ubuntu/Cubic to Debian/live-build: what changes

This document covers what one-time changes are needed to move EmComm Tools from Ubuntu/Cubic to Debian/live-build,
and why.

Once these changes are merged, this document becomes irrelevant and can be removed.

How to build ISOs from now on is in
[ISO-BUILD-PLAN.md](ISO-BUILD-PLAN.md) and should persist.

## Goals

Make the smallest set of changes that:

1. Moves EmComm Tools from Ubuntu/Cubic to Debian/live-build.
2. Builds one ISO suitable for distribution worldwide.
3. Lets the person installing decide whether to install the encryption tools.
4. Boots, installs and runs with no internet. The optional VARA and xara
   installs still need internet (VARA can instead be restored from a WINE
   backup).
5. Keeps the same application versions as r7 where possible (see
   [Version parity with r7](#version-parity-with-r7)).
6. Keeps r7's look and style (see [Beyond the minimum](#beyond-the-minimum)).

## For the ETC developer to review

The following describe changes that need decisions from the ETC Dev before moving forward

### Changes in the user experience

**New behavior: the ISO is a live system.** It boots into a working GNOME
desktop with EmComm Tools, without installing anything. Installing to disk only
happens when the user clicks **Install EmComm Tools**.

**et-api's missing data file (upstream bug, also in r7).** et-api 1.3.0
indexes NWS forecast zones from `data/weather-forecast-zone.csv`, but neither
its release nor ETC provides that file, so et-api fails at first start. Without
a GPS it exits and systemd restarts it; with a GPS connected, its gpsd
connection keeps the failed process alive with no web server, so et-predict and
et-aircraft get nothing until et-api is restarted by hand (every live boot, and
an installed system's first login). The file is the National Weather Service's
public-domain zone–county correlation file, which matches et-api's format
exactly. The ISO build hook downloads it (pinned version and checksum) to
that path, so et-api's install script and config are unchanged from r7.
**For the ETC developer to review:** publish the file with et-api.

**Java version: OpenJDK 17 instead of 20.** r7 uses OpenJDK 20, which Debian 12 doesn't have. This branch uses Debian's
OpenJDK 17 (Debian security updates). ETC's Java apps need at most Java 11
(et-api) and Java 9 (YAAC), and et-api runs on 17 in testing. The alternative
is a non-Debian JDK 20+ (for example Eclipse Temurin), with its own downloads
and updates. Revisit if et-api or YAAC ever needs Java 18 or later.

**Sound server: PipeWire instead of PulseAudio.** Debian 12's GNOME uses PipeWire (with `pipewire-pulse` and WirePlumber); r7 on
Ubuntu 22.04 uses PulseAudio. This branch doesn't change either: it's the
desktop default each distribution ships. ETC's radio apps mostly open the
radio's sound card directly through ALSA (for example JS8Call's
`sysdefault:CARD=ET_AUDIO`, Direwolf's `ADEVICE`), which works under either.
Apps that go through the sound server (WINE/VARA, the desktop's own sounds)
now go through PipeWire. Checked in a VM with a DigiRig Lite and a built-in
card and on a laptop with a DigiRig Lite: JS8Call, WSJT-X, Winlink Ardop all operated as expected.

Still to check on hardware: VARA under WINE.

r7's install process asked the ISO builder certain questions. The new ISO build
asks none, so each is handled differently now:

| r7 question | Where | Now |
|---|---|---|
| OSM state map (Navit) | `download-osm-maps.sh` | Not in the ISO. **Decision needed:** how users add state maps after install, for example copying `.osm.pbf` files in and converting them with `maptool`, or running `download-osm-maps.sh` (needs internet; it saves into `/etc/skel`) |
| ETC map tiles: US, Canada or world | `download-et-maps.sh` | The world map (80 MB) is in the ISO. **Decision needed:** how users add US or Canada tiles after install, for example copying `.mbtiles` files in, or running `download-et-maps.sh` (needs internet; it saves into `/etc/skel`) |
| Wikipedia file (`ET_EXPERT`) | `download-wikipedia.sh` | No `.zim` files ship with the ISO; the Kiwix reader is installed. **Decision needed:** how users add `.zim` files after install, for example copying them in, or running `download-wikipedia.sh` (needs internet; it saves into `/etc/skel`) |
| VARA/WINE notes (`ET_EXPERT`) | `install-wine.sh`, `wine.txt` | WINE, winetricks and the VARA add-on scripts (`~/add-ons/wine`) are in the ISO; VARA itself isn't. Users install it after install, with internet or by restoring a WINE backup made with `05-backup-wine-install.sh` (`cd ~ && tar -xzf etc-wine-backup-*.tar.gz`). `~/add-ons/wine/README.md` covers both |
| xara modem | `install-xara.sh`, `scripts/xara.md` | Built in r7 only when the builder supplies the source tarball; not in this ISO (Rust is). **For the ETC developer to review:** suggested post-install scripting, so users build xara from their own source with `install-xara.sh` |
| Encryption tools | `install-crypto.sh` | Installed without asking in r7. Now asked by the installer's **Optional software** page (**Skip encryption tools** or **Install encryption tools**); not selected by default. The page (and `install.sh`'s prompt) says not to install them where encryption is illegal |

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

Branch `feature/debian-live-iso` against `release/r7` at build37
(`emcomm-tools-os-community-20261111-r7-build37`, merged in): **97 files,
+1,936 / −341 lines** (not counting this document).

It's less than it looks:

- 17 files are the install guide's screenshots, plus the guide itself.
- 23 files are moves or deletions with no new logic: 12 renames (slideshow
  images, encryption guide files, the GNOME settings file) and 11 deleted
  Ubuntu/Cubic files.
- Most edits to existing scripts are 1–10 lines.
- The branch combines three separate efforts: the Debian port, the new ISO
  build, and the encryption tools opt-in.

## By category

| # | Category | Files | Lines +/− | Why |
|---|---|---|---|---|
| 1 | Installer: Ubiquity → Calamares | 23 | +344 / −209 | Ubuntu's installer doesn't exist on Debian. The 8 slideshow images only moved. The 9 Ubiquity HTML slides were deleted, and the same 8 slides were ported to one Calamares `show.qml` (264 lines). |
| 2 | Docs | 20 | +310 | Release notes; developer build guide; end-user install guide. |
| 3 | New ISO build (live-build) | 17 | +723 | Replaces Cubic. All new files; nothing existing changed. |
| 4 | Debian package and OS differences | 16 | +115 / −74 | A small edit in each script that named an Ubuntu package, version or URL. |
| 5 | Encryption tools opt-in | 11 | +221 / −23 | Distribution requirement, not Debian's. `install-crypto.sh` is most of it. The guide files (`gpg-cheatsheet.md`, `steghide.md`, `steghide.jpg`) were moved unchanged, so only users who choose the tools get them. |
| 6 | Desktop parity with r7 | 6 | +77 / −20 | Ubuntu builds in its dock, theme and tray icons; Debian needs them added. No automatic update checks, as in r7. |
| 7 | Users | 2 | +92 | Users created by the installer get ETC's `et-data` group as primary. |
| 8 | Build mode | 2 | +54 / −15 | `install.sh` asks nothing during the image build. |

## Beyond the minimum

Changes mostly needed to address goal #6, but aren't strictly needed, and why they're in. Together they're
about 45% of the added lines; dropping them gives the smallest possible
migration, at the cost of r7's look and some live-session usability:

| Change | Why it's here | Could drop? |
|---|---|---|
| GNOME parity: Yaru theme, dock, desktop icons, tray icons, window buttons | Look and version parity with r7 | Yes, if r7's look isn't required |
| Calamares slideshow ported from Ubiquity (`show.qml`) | Branding parity | Yes; Calamares works without it |
| Installer stylesheet (`stylesheet.qss`): the encryption choices drawn as buttons | Encryption is legally restricted in some jurisdictions, so installing the tools must be a clear, deliberate choice | Yes; the page works without it |
| GRUB menus branded: ETC background on the live ISO's boot menu; "EmComm Tools" and the same background on installed systems | Branding parity | Yes; the stock Debian menus work |
| ETC boot splash watermark: Debian's logo diverted (Debian's plymouth puts its own in) | Branding parity | Yes; Debian's logo shows instead |
| Live-session polish: installer icon shown correctly, installer starts without a password, ETC dock in the live session, callsign/grid/Winlink password saved in the live session carried into the installed system | Usability of the live session | Yes; the ISO works without them |
| `et-fix-primary-group` (installer step) | ETC shares files through the `et-data` group, and Calamares can't set a primary group | Only by changing ETC's group design |
| `configure-existing-user.sh` | Only for running `install.sh` on an existing Debian system; the ISO doesn't use it | Yes, if only the ISO is supported |
| `configure-user.sh` doesn't fail if `et-data` exists | Lets `install.sh` run twice on the same system | Yes; the ISO build runs it once |
| Update checks off: GNOME Software settings and login service, apt's daily timers | r7 removed Ubuntu's update-notifier; an offline system shouldn't try | No (requested) |
| `build.sh` keeps live-build's download cache | Faster rebuilds | Yes |
| Read-only repository copy in `/opt/emcomm-tools-os-community` | ETC's scripts and test suite on every system, matching the ISO; r7's Cubic steps leave their extracted copy in the image (Cubic's terminal starts in `/root`), out of users' reach | Yes; the test suite would be copied in instead |
| End-user install guide with screenshots ([INSTALL-GUIDE.md](docs/INSTALL-GUIDE.md)): checking the download, Ventoy stick, booting, the live system, installing | The installer and boot steps changed from r7; users need current instructions | Yes; it's documentation only |

## Verified (11–12 Nov 2026)

In VMs with the network unplugged, except the rows marked **Laptop**, which
were on real hardware:

| Test | Result |
|---|---|
| Build (`live-build/build.sh`) | Completes; `install.sh` 0 failed steps (last completed build: 4353008, with build37 merged) |
| ISO contents | No build files, logs, SSH host keys or machine-id; encryption tools prepared, not installed; WINE (32- and 64-bit), winetricks and the VARA add-on scripts included; read-only repository copy in `/opt/emcomm-tools-os-community` (12 MB); installer `stylesheet.qss` in the branding; et-api's `weather-forecast-zone.csv` (NWS, checksum verified) in its data folder |
| UEFI, Secure Boot on: live session | ETC boot menu, splash, desktop and dock; installer starts without a password; Optional software page text, including the encryption legal notice; slideshow advances; installer sidebar steps readable (ISO from c1a32a6); Optional software page's Skip/Install buttons (applied by hand in the live session, then committed in 7191f84) |
| UEFI, Secure Boot on: install with encryption tools | Tools and guides installed from the ISO |
| UEFI, Secure Boot on: install without encryption tools | No tools, guides or marker; add-on still available |
| UEFI, Secure Boot on: installed system | Boots; GRUB menu shows "EmComm Tools" with the ETC background; ETC splash, dock, wallpaper; `et-data` primary group; SSH server running; apt sources include `contrib` and `non-free`; update checks off; ETC test suite passes except xara (no source package) |
| BIOS (no UEFI): live boot and install | Boots and installs; BIOS GRUB installed from the ISO (tested before GRUB branding was added) |
| UEFI, Secure Boot on: live settings carry-over | Callsign and grid saved in the live session are in the installed user's `user.json`, with the `first-login-complete` marker, owned by the new user; setup doesn't open at first login. Passed in the ISO built from 180a991. The same ISO failed the **Cancel** case: Cancel also writes the marker, so the default settings were copied and setup didn't open. Fixed by also checking that `user.json` differs from the `/etc/skel` default; the check passed on the installed system, the fix is in the ISO built from 22beb66 |
| Ventoy 1.1.10, UEFI, Secure Boot off | ISO boots from a Ventoy stick to the ETC boot menu and live desktop |
| Laptop, live session (ISO from 4353008, UEFI, Secure Boot off), GPS, DigiRig Mobile and SDR connected | `validate-install.sh`: 92 passed, 0 failed. et-api starts once with no restart; et-predict and et-aircraft work without restarting it; aircraft received by the SDR are identified from et-api's FAA data (US-registered; others, such as Canadian, have no entry). The et-api hang was reproduced on an earlier ISO, before the NWS file was included |
| Laptop, live session, DigiRig Lite | JS8Call, WSJT-X and Winlink over ARDOP use the DigiRig for audio input and output |

## Files in each category

### 1. Installer: Ubiquity → Calamares

| File | Change |
|---|---|
| `overlay/usr/share/ubiquity-slideshow/slides/*.html` (9) | Deleted |
| `overlay/usr/share/ubiquity/pixmaps/ubuntu_installed.png` | Deleted |
| `overlay/etc/calamares/branding/emcomm-tools/screenshots/*.png` (7), `background.png` | Moved from the Ubiquity slideshow, unchanged |
| `overlay/etc/calamares/branding/emcomm-tools/show.qml` | New: the same 8 slides, as Calamares QML |
| `overlay/etc/calamares/branding/emcomm-tools/branding.desc`, `logo.png` | New: installer name, logo and sidebar colors |
| `overlay/etc/calamares/branding/emcomm-tools/stylesheet.qss` | New: the Optional software page's choices shown as buttons |
| `scripts/debrand.sh` | Installs the Calamares branding instead of Ubiquity's; drops the Cubic kernel reinstall |

### 2. Docs

| File | Change |
|---|---|
| `RELEASES.md` | Release entry |
| `ISO-BUILD-PLAN.md` | New: developer guide for building and publishing ISOs |
| `docs/INSTALL-GUIDE.md`, `docs/install-guide/images/` | New: end-user guide (checking the download, Ventoy USB stick, live system, installing) |

### 3. New ISO build (live-build)

| File | Purpose |
|---|---|
| `live-build/build.sh` | The one build command |
| `live-build/config/hooks/normal/0900-emcomm-tools.hook.chroot` | Runs `install.sh` inside the image (before Debian's cleanup hooks); adds et-api's NWS forecast zone data file; keeps a read-only repository copy in `/opt/emcomm-tools-os-community`; removes build files; ETC launchers in the live dock |
| `live-build/config/hooks/normal/0910-grub-pc-pool.hook.binary` | Adds BIOS GRUB to the ISO's package pool (it conflicts with UEFI GRUB, so it can't go in the package list) |
| `tests/validate-install.sh` | New: checks an installed system (or the live session) and runs ETC's app tests; PASS/FAIL/WARN/SKIP summary |
| `live-build/config/package-lists/emcomm-tools.list.chroot` | GNOME and Calamares in the image |
| `live-build/config/package-lists/installer.list.binary` | GRUB packages carried in the ISO, so installs work offline |
| `live-build/config/includes.chroot/etc/calamares/settings.conf` | Installer steps (Debian's, plus ETC's five) |
| `live-build/config/includes.chroot/etc/calamares/modules/users.conf` | Groups for new users |
| `live-build/config/includes.chroot/etc/calamares/modules/packagechooser-crypto.conf` | Optional software page: **Skip encryption tools** (default) or **Install encryption tools** |
| `live-build/config/includes.chroot/etc/calamares/modules/contextualprocess-crypto.conf` | Installs the encryption tools offline if selected |
| `live-build/config/includes.chroot/etc/calamares/modules/shellprocess-etc-setup.conf` | ETC setup: primary group, SSH host keys |
| `live-build/config/includes.chroot/etc/calamares/modules/shellprocess-etc-live-settings.conf` | Carries the callsign, grid and Winlink password saved in the live session to the new user |
| `live-build/config/includes.chroot/etc/calamares/modules/shellprocess-etc-sources.conf` | apt sources: Debian's installer drops `contrib` and `non-free`; this puts them back |
| `live-build/config/includes.chroot/usr/local/sbin/et-carry-live-settings` | Copies the callsign, grid and Winlink password saved in the live session to the new user |
| `live-build/config/includes.chroot/usr/local/bin/et-trust-live-installer` | Live session: marks the installer icon as trusted on GNOME |
| `live-build/config/includes.chroot/etc/xdg/autostart/et-trust-live-installer.desktop` | Live session: runs `et-trust-live-installer` at login |
| `live-build/config/includes.chroot/usr/lib/live/config/2500-etc-installer-polkit` | Live session: the installer starts without a password |

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

### 5. Encryption tools opt-in

| File | Change |
|---|---|
| `scripts/install-crypto.sh` | New: installs GPA, PFTE, VeraCrypt, steghide, gpg and guides; or prepares them for the installer and installs them offline |
| `scripts/crypto-docs/gpg-cheatsheet.md`, `steghide.md`, `steghide.jpg` | Moved unchanged from `overlay/etc/skel/Desktop/offline/crypto/` (which every user got), so they're only installed with the tools |
| `scripts/install-offline-lib-crypto.json`, `install-offline-lib.json` | AmRRON key and GPG guide moved to the crypto list |
| `scripts/install-offline-lib.sh` | Takes a file list and destination |
| `scripts/install-pfte.sh`, `install-veracrypt.sh` | Download-only mode, for the offline install |
| `tests/test-gpa.sh`, `test-pfte.sh` | Pass when the tools weren't chosen |

### 6. Desktop parity with r7

| File | Change |
|---|---|
| `overlay/usr/share/glib-2.0/schemas/90_emcomm-tools.gschema.override` | Renamed from `90_ubuntu-settings`; dock, extensions, window buttons, dark-style wallpaper, update notifications off |
| `scripts/configure-gnome.sh` | Install Yaru theme and the dock, desktop-icon and tray-icon extensions |
| `scripts/install-branding.sh` | Boot splash and wallpaper on Debian; ETC watermark instead of Debian's logo (Debian's plymouth swaps it in); GRUB menu name and background |
| `logos/emcomm-tools-boot-800x600.png`, `-640x480.png` | New: GRUB menu background for the live ISO (via `live-build/build.sh`) and installed systems |
| `overlay/etc/skel/.config/autostart/org.gnome.Software.desktop` | New: GNOME Software's update service doesn't start at login (the app still opens) |

### 7. Users

| File | Change |
|---|---|
| `overlay/opt/emcomm-tools/bin/et-fix-primary-group` | New: `et-data` as primary group for users the installer creates |
| `scripts/configure-existing-user.sh` | New: sets up the user when `install.sh` runs on an existing Debian system (not used by the ISO) |

### 8. Build mode

| File | Change |
|---|---|
| `scripts/install.sh` | `ET_BUILD=1`: no prompts; only the world map; encryption tools prepared, not asked |
| `scripts/download-et-maps.sh` | Country can be passed instead of asked |
