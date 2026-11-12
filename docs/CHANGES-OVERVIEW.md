# Moving EmComm Tools from Ubuntu/Cubic to Debian/live-build: changes

What changes, once, to move EmComm Tools from Ubuntu/Cubic to Debian/live-build,
and why. How to build ISOs from now on is in
[ISO-BUILD-PLAN.md](../ISO-BUILD-PLAN.md).

## Goal

The smallest change that:

1. moves EmComm Tools from Ubuntu/Cubic to Debian/live-build: Ubuntu 22.10
   to Debian 12, and Cubic to Debian's live-build,
2. builds an ISO (the build needs internet),
3. leaves the encryption tools to the person installing, and
4. produces an ISO that boots, installs and runs with no internet.

## Decision for the ETC developer: Java version

r7 installs OpenJDK 20. Debian 12 doesn't have OpenJDK 20; its Java is
OpenJDK 17, which gets Debian security updates. This branch uses OpenJDK 17.

Two ETC apps use Java, and neither needs more than 17:

| App | Newest Java its compiled code needs |
|---|---|
| et-api 1.3.0 (Spring Boot 2.4.13, built with JDK 20) | 11 |
| YAAC (`latest` zip) | 9 |

Measured 10 Nov 2026 by reading the class-file version of every class,
including nested jars. On the test systems et-api's service runs on OpenJDK 17
and answers on port 1981.

| Option | Effect |
|---|---|
| **OpenJDK 17 from Debian** (this branch) | No extra work; security updates from Debian |
| OpenJDK 20 or newer from another source (for example Eclipse Temurin) | Matches r7's version; adds a non-Debian download to `install-base.sh` and its own update path |

Revisit if a future et-api or YAAC needs Java 18 or later. Spring Boot 2.4
predates official Java 17 support, so watch et-api in hardware testing.

## Size

Branch `feature/debian-live-iso` against `release/r7`: **73 files,
+1,411 / −341 lines** (not counting this document).

It's less than it looks:

- 22 files are moves or deletions with no new logic: 12 renames (slideshow
  images, encryption guides, the GNOME settings file) and 10 deleted
  Ubuntu/Cubic files.
- Most edits to existing scripts are 1–10 lines.
- The branch combines three separate jobs: the Debian port, the new ISO
  build, and the encryption tools opt-in.

## By category

| # | Category | Files | Lines +/− | Why |
|---|---|---|---|---|
| 1 | Installer: Ubiquity → Calamares | 22 | +312 / −209 | Ubuntu's installer doesn't exist on Debian. The 8 slideshow images only moved. The 9 Ubiquity HTML slides were deleted, and the same 8 slides were ported to one Calamares `show.qml` (264 lines). |
| 2 | New ISO build (live-build) | 15 | +546 | Replaces Cubic. All new files; nothing existing changed. |
| 3 | Encryption tools opt-in | 11 | +215 / −23 | Product requirement, not Debian's. `install-crypto.sh` is most of it; the 3 guides only moved. |
| 4 | Debian package and OS differences | 16 | +115 / −74 | A small edit in each script that named an Ubuntu package, version or URL. |
| 5 | Desktop parity with r7 | 4 | +67 / −20 | Ubuntu builds in its dock, theme and tray icons; Debian needs them added. No automatic update checks, as in r7. |
| 6 | Users | 2 | +92 | Users created by the installer get ETC's `et-data` group as primary. |
| 7 | Build mode | 2 | +53 / −15 | `install.sh` asks nothing during the image build. |
| 8 | Docs | 1 | +11 | Release notes. |

## Beyond the minimum

Changes the goal didn't strictly need, and why they're in:

| Change | Why it's here | Could drop? |
|---|---|---|
| GNOME parity: Yaru theme, dock, desktop icons, tray icons, window buttons | Look and version parity with r7 | Yes, if r7's look isn't required |
| Calamares slideshow ported from Ubiquity (`show.qml`) | Branding parity | Yes; Calamares works without it |
| `configure-existing-user.sh` | Only for running `install.sh` on an existing Debian system; the ISO doesn't use it | Yes, if only the ISO is supported |
| Live-session polish: installer icon shown correctly, installer starts without a password, ETC dock in the live session | Usability of the live session | Yes; the ISO works without them |
| Update checks off: GNOME Software settings and login service, apt's daily timers | r7 removed Ubuntu's update-notifier; an offline system shouldn't try | No (requested) |
| `et-fix-primary-group` (installer step) | ETC shares files through the `et-data` group, and Calamares can't set a primary group | Only by changing ETC's group design |
| `build.sh` keeps live-build's download cache | Faster rebuilds | Yes |

## Gaps against the goal

| Gap | Effect |
|---|---|
| First-login map step not written yet | The ISO has only the 80 MB global map. r7 included a state map and country tiles chosen at build; on the ISO there's currently no simple way to get them |
| xara | Upstream source was withdrawn; built only if `scripts/xara-*.tar.gz` is provided. Deferred to the next release |
| GRUB boot menu | live-build's stock Debian menu, not ETC-branded |
| Installer slideshow | May not advance between slides; not checked |

## Verified (11 Nov 2026)

In a UEFI VM with Secure Boot on:

| Test | Result |
|---|---|
| Build (`live-build/build.sh`) | Completes; `install.sh` 0 failed steps |
| ISO contents | No build files, logs, SSH host keys or machine-id; encryption tools prepared, not installed |
| Live session | ETC desktop, dock and boot splash; installer starts without a password |
| Install with encryption tools selected | Tools and guides installed |
| Installed system | Boots with Secure Boot on; ETC splash, dock, wallpaper; `et-data` primary group; SSH server running; ETC test suite passes except xara (no source package) |
| Update checks | GNOME Software service not started at login; apt timers disabled |
| No network: live boot, install with encryption tools, installed system | Passes: everything installed from the ISO, including GRUB and the encryption tools |

Not tested yet: install with encryption tools not selected, BIOS install,
hardware with a radio (CAT, audio, JS8Call, WSJT-X, VARA under WINE). Fixed
after the last ISO build: update checks off and restoring
`contrib`/`non-free` in apt sources (both checked on an installed system, not
yet in a built ISO), and the Optional software page's "No optional software"
text (not checked yet).

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
| `live-build/config/includes.chroot/etc/calamares/settings.conf` | Installer steps (Debian's, plus ETC's four) |
| `live-build/config/includes.chroot/etc/calamares/modules/*.conf` (5) | Groups for new users, Optional software page, offline encryption install, ETC setup (primary group, SSH host keys), apt sources (Debian's installer drops `contrib` and `non-free`; this puts them back) |
| `live-build/config/includes.chroot/…/et-trust-live-installer` (2) | Live session: shows the installer icon as trusted on GNOME |
| `live-build/config/includes.chroot/usr/lib/live/config/2500-etc-installer-polkit` | Live session: the installer starts without a password |
| `ISO-BUILD-PLAN.md` | Developer guide: building and publishing ISOs |

### 3. Encryption tools opt-in

| File | Change |
|---|---|
| `scripts/install-crypto.sh` | New: installs GPA, PFTE, VeraCrypt, steghide, gpg and guides; or prepares them for the installer and installs them offline |
| `scripts/crypto-docs/*` (3) | Moved from `/etc/skel`, unchanged, so they're only installed with the tools |
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
| `scripts/install-branding.sh` | Boot splash and wallpaper on Debian; ETC watermark instead of Debian's logo (Debian's plymouth swaps it in) |
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

`RELEASES.md`: release entry. The developer build guide is `ISO-BUILD-PLAN.md`
(category 2).
