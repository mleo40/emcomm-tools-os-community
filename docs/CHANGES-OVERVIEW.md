# Debian 12 live ISO: overview of changes

Branch `feature/debian-live-iso` against `release/r7`: **68 files,
+1,202 / −341 lines** (not counting this document).

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
| 2 | New ISO build (live-build) | 12 | +370 | Replaces Cubic. All new files; nothing existing changed. |
| 3 | Encryption tools opt-in | 11 | +213 / −23 | Product requirement, not Debian's. `install-crypto.sh` is most of it; the 3 guides only moved. |
| 4 | Debian package and OS differences | 15 | +99 / −74 | A small edit in each script that named an Ubuntu package, version or URL. |
| 5 | Desktop parity with r7 | 3 | +53 / −20 | Ubuntu builds in its dock, theme and tray icons; Debian needs them added. |
| 6 | Users | 2 | +92 | Users created by the installer get ETC's `et-data` group as primary. |
| 7 | Build mode | 2 | +53 / −15 | `install.sh` asks nothing during the image build. |
| 8 | Docs | 1 | +10 | Release notes. |

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
| `live-build/config/hooks/normal/9000-emcomm-tools.hook.chroot` | Runs `install.sh` inside the image; removes build files and logs |
| `live-build/config/package-lists/emcomm-tools.list.chroot` | GNOME and Calamares in the image |
| `live-build/config/package-lists/installer.list.binary` | GRUB packages carried in the ISO, so installs work offline |
| `live-build/config/includes.chroot/etc/calamares/settings.conf` | Installer steps (Debian's, plus ETC's three) |
| `live-build/config/includes.chroot/etc/calamares/modules/*.conf` (4) | Groups for new users, Optional software page, offline encryption install, primary group |
| `live-build/config/includes.chroot/…/et-trust-live-installer` (2) | Live session: shows the installer icon as trusted on GNOME |
| `ISO-BUILD-PLAN.md` | How the build works |

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
| `scripts/remove-packages.sh` | Remove Debian's extra apps and first-login wizard; keep GNOME |
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
| `scripts/install-branding.sh` | Boot splash and wallpaper on Debian |

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

`RELEASES.md`: release entry. Build instructions are in `ISO-BUILD-PLAN.md`.
