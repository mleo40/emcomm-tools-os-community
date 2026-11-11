# Plan: EmComm Tools on Debian 12

Branch `feature/debian-base`, from tag `emcomm-tools-os-community-20261027-r7-build34`.

## Flow

1. Install Debian 12 (bookworm) with the GNOME desktop. Internet required.
   Leave the root password **empty**, so the installer gives the first user
   `sudo`.
2. `cd scripts && sudo ./install.sh`. The last step asks
   *"Install optional encryption tools? [y/N]"* (default No).
3. Optional: `sudo ./build-iso.sh` builds a live ISO from the running system,
   either clean (to deploy for others) or personal (the user's own data,
   portable). The ISO contains whatever software is installed, including the
   encryption tools if they were chosen.

## Package and behaviour changes

| File | Change |
|---|---|
| `overlay/etc/apt/sources.list` | `deb.debian.org` bookworm, bookworm-updates, bookworm-security; `main contrib non-free non-free-firmware` |
| `install-dev-tools.sh` | Remove the Cubic/PPA block |
| `install-ubuntu-image-tools-only.sh` | Delete |
| `install-base.sh` | `openjdk-20-jdk` → `openjdk-17-jdk` (see Java note); move `steghide` and `gpg` to `install-crypto.sh` |
| `install-python.sh` | `python2 python-setuptools` → `python3-setuptools python-is-python3`; remove the `update-alternatives` line that points `python` at python2 |
| `install-mbutil.sh` | Install with python3 |
| `install-wsjtx.sh` | Remove `libqcustomplot2.0` (the WSJT-X 2.7.0 `.deb` doesn't depend on it, and bookworm doesn't have it) |
| `install-sdrpp.sh` | `sdrpp_ubuntu_jammy_amd64.deb` → `sdrpp_debian_bookworm_amd64.deb` |
| `install-veracrypt.sh` | `Ubuntu-22.04` → `Debian-12` `.deb` |
| `remove-packages.sh` | Remove `update-manager` and `update-notifier` from the list (they aren't in Debian, and an unknown name makes the whole purge fail); add `firefox-esr` (r7 had no Firefox, because Ubuntu's Firefox is a snap that gets purged with `snapd`) |
| `configure-user.sh` | Also apply the user setup to the **existing** user (`$SUDO_USER`), who now exists before `install.sh` runs: copy `/etc/skel` into their home without overwriting, chown it, set the primary group to `et-data` (GID 1981, as `USERS_GID` does for new users), and add the `EXTRA_GROUPS` from `adduser.conf` (`dialout`, `bluetooth` and the rest). Without this, the user has no radio/serial access and none of ETC's home-folder files, including the Reticulum installs in `/etc/skel/.local` |
| `overlay/etc/crontab` | Remove the `@reboot` line that copies `sources.list` from `/root/emcomm-tools-os-community/…`. That path only existed in the Cubic build chroot; `update-apt.sh` already installs `sources.list` |
| `debrand.sh` | Replace the Ubiquity slideshow install with the Calamares branding install (see Branding); remove the kernel reinstall/`update-initramfs` block |
| `install-branding.sh` | Remove the `ubuntu-logo.png`, `warty-final-ubuntu.png` and Ubiquity pixmap steps; keep the spinner and watermark copy; install `plymouth`; add `plymouth-set-default-theme -R spinner`; add `splash` to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub` and run `update-grub` (Debian's default is `quiet` only) |
| `90_ubuntu-settings.gschema.override` | Rename to `90_emcomm-tools.gschema.override`; remove the `apps/update-manager` and `com/ubuntu/update-notifier` sections |
| `configure-gnome.sh` | Use the renamed override; install `yaru-theme-gtk yaru-theme-icon yaru-theme-gnome-shell`. Also install and enable the three GNOME extensions Ubuntu ships built in: `gnome-shell-extension-dashtodock` (the always-visible dock that shows the `favorite-apps` launchers), `gnome-shell-extension-desktop-icons-ng` (shows `~/Desktop/offline` on the desktop) and `gnome-shell-extension-appindicator` (tray icons). Enable them through `org.gnome.shell enabled-extensions` in the override, with dash-to-dock set to Ubuntu's layout (left side, fixed, full height). Vanilla Debian GNOME has none of these, so the launchers that `REGRESSION.md` checks would only appear in the Activities overview |
| `install.sh` | Remove `install-gpa.sh`, `install-pfte.sh` and the VeraCrypt line; add the encryption prompt as the last step |
| `install-offline-lib.json` | Move the AmRRON `.asc` key and GPG guide entries to `install-crypto.sh` |
| `README.md`, `RELEASES.md` | Document the flow above |

**Java note:** Debian 12 has no OpenJDK 20, so the build uses Debian's
OpenJDK 17, which gets security updates. Only two apps use Java, and the
compiled code in both needs Java 11 at most:

| App | Newest Java its compiled code needs |
|---|---|
| et-api 1.3.0 (Spring Boot 2.4.13, built with JDK 20) | 11 |
| YAAC (`latest` zip, all 20 jars) | 9 |

Measured 10 Nov 2026 by reading the class-file version of every class,
including nested jars. If a future YAAC or et-api needs Java 18 or later,
revisit this.

Version changes that come with bookworm and need no script edit. All 165
packages the scripts install were compared, kinetic against bookworm (10 Nov
2026); everything not listed keeps the same major.minor version:

| Package | r7 | bookworm |
|---|---|---|
| wine / winetricks | 7.0 / 20220411 | 8.0 / 20230212 |
| thunderbird | 102 | 153 ESR |
| conky | 1.12 | 1.18 |
| kiwix | 2.2 | 2.3 |
| system python3 (ETC's own `/opt/python` 3.11.17 is unchanged) | 3.10 | 3.11 |
| openssh-server, chrony, git, curl, cmake | minor bumps | minor bumps |
| kernel | 5.19 | 6.1 |
| installer (ISO) | Ubiquity | Calamares |

The pip installs (Reticulum, NomadNet, Partyline) use ETC's own
`/opt/python`, so Debian's restriction on system-wide pip installs (PEP 668)
doesn't affect them.

## Optional encryption tools

New `scripts/install-crypto.sh` installs:

- GNU Privacy Assistant (`install-gpa.sh`)
- Paranoia File & Text Encryption (`install-pfte.sh`)
- VeraCrypt (`install-veracrypt.sh`)
- steghide, gpg
- the offline guides `gpg-cheatsheet.md`, `steghide.md` and `steghide.jpg`
  (moved out of `overlay/etc/skel/Desktop/offline/crypto/`)
- the AmRRON public key and GPG verification guide

Behaviour:

- `install.sh` runs it only if the user answers `y`. `ET_CRYPTO=yes|no`
  pre-answers the prompt.
- It can be run on its own later: `sudo ./install-crypto.sh` from the repo.
  Systems installed from a clean ISO have no repo checkout, so `install.sh`
  also copies the script, its three `install-*.sh` helpers and the guides to
  `/opt/emcomm-tools/add-ons/crypto/` (copied, not run). Run it from there with
  `sudo /opt/emcomm-tools/add-ons/crypto/install-crypto.sh`.
- `gpg` itself stays on every system: Debian's GNOME desktop depends on
  `gnupg`. The opt-in covers ETC's explicit install and the guides.
- It writes `/etc/emcomm-tools/crypto-enabled`, which `build-iso.sh` uses to add
  a `-crypto` suffix to the ISO name.
- The Calamares full-disk-encryption checkbox stays visible and unchecked.

## ISO build (`scripts/build-iso.sh`)

`build-iso.sh` asks which ISO to build:

```
1) Clean system: ready to deploy for someone else (default)
2) Personal system: your accounts, settings and files, portable to any machine
```

| | 1. Clean | 2. Personal |
|---|---|---|
| eggs command | `eggs remaster` | `eggs remaster --clone`, or `--crypted` if encryption is chosen |
| User accounts and `/home` | excluded; live user created from `/etc/skel`, first-login setup runs | included; boots as the user's own account |
| Wi-Fi connections, SSH host keys | removed | kept |
| Apt caches, `/tmp/et`, logs | removed | removed |
| machine-id | reset | reset |
| Live username and password | set in `/etc/penguins-eggs.d/eggs.yaml` | the user's own |
| Groups for the live user and for users Calamares creates | primary `et-data` plus `adduser.conf`'s `EXTRA_GROUPS`, set in eggs' live-user config and Calamares' `users.conf` (`defaultGroups`). Calamares uses `useradd`, which ignores `adduser.conf` | unchanged from the source system |
| File name | `emcomm-tools-os-community-<date>[-crypto].iso` | `emcomm-tools-personal-<hostname>-<date>.iso` |

Option 2 only:

- A warning before building: the ISO holds the user's private data
  (Winlink/Pat credentials, GPG keys, Wi-Fi passwords, messages), so anyone
  with the file has them.
- Then the prompt *"Encrypt the ISO with a passphrase? [y/N]"* (default No,
  per the encryption opt-in rule). `y` uses `--crypted` (LUKS), and the
  passphrase is asked for at every boot.

Both kinds:

1. Install the penguins-eggs `.deb` from GitHub releases, **pinned to a tested
   version** (its CLI changed from `eggs produce` to `eggs remaster`), and
   `calamares`.
2. Clean up as in the table, then run `eggs remaster` with the right flags.
   The output goes to `/home/eggs/`.
3. The ISO boots to a live GNOME session with an "Install" launcher for
   Calamares. Changes are lost on reboot unless the stick uses Ventoy
   persistence. Expect several GB (more with `ET_EXPERT`), so target USB.

## Branding

Same EmComm Tools branding as r7, moved from Ubuntu's mechanisms to Debian's:

| Item | r7 (Ubuntu) | Debian |
|---|---|---|
| Boot splash | Plymouth `spinner` theme with ETC throbber, animation and watermark PNGs | Same files, same theme (Debian's `plymouth-themes`), made the default with `plymouth-set-default-theme -R spinner`; `splash` on the kernel command line |
| Installer slideshow | 8 HTML slides in `overlay/usr/share/ubiquity-slideshow/slides/` (welcome, et-user, et-radio, et-mode, et-predict, et-mail, et-aircraft, et-reticulum) | The same 8 slides ported to a Calamares QML slideshow. Each slide is a title, 2–3 lines of text and the existing screenshot, so the port keeps the content one-for-one |
| Installer logo and name | `ubuntu_installed.png` | Calamares `branding.desc`: product name "EmComm Tools OS Community", logo `logos/et-spinner/et-512x512-icon.png` |
| Wallpaper | gschema override plus `warty-final-ubuntu.png` copy | gschema override only |
| Live ISO boot menu | Ubuntu's | eggs theme: ETC name and background |

Files:

- `overlay/etc/calamares/branding/emcomm-tools/branding.desc`
- `overlay/etc/calamares/branding/emcomm-tools/show.qml`
- `overlay/etc/calamares/branding/emcomm-tools/screenshots/`: move the 7 PNGs
  here from `overlay/usr/share/ubiquity-slideshow/slides/screenshots/`
- Delete `overlay/usr/share/ubiquity-slideshow/` and
  `overlay/usr/share/ubiquity/pixmaps/ubuntu_installed.png`

Check: eggs generates its own Calamares config, so the `emcomm-tools`
branding may have to go through eggs' theme option rather than
`/etc/calamares/settings.conf`. Confirm on the pinned eggs version.

## New files

- `scripts/install-crypto.sh`
- `scripts/build-iso.sh`
- Calamares branding: `branding.desc`, `show.qml` (screenshots moved, not new)

## Order of work

1. Make the package changes; `install.sh` completes on a fresh Debian 12 VM
   with a clean `/tmp/et/et.log`.
2. Encryption opt-in: test both answers and the standalone run.
3. `build-iso.sh`: for each option, boot the ISO live and install it to a
   second VM. Repeat option 1 with the encryption tools installed, and option 2
   with `--crypted`.
4. `tests/run-test-suite.sh` and `REGRESSION.md` on the installed system and on
   hardware.
5. Branding: boot splash on the live ISO and on the installed system, all 8
   slides shown during the Calamares install, ETC boot menu on the ISO.
6. Docs.

## To check

- Prebuilt `.deb`s: the dependencies of all of them resolve on bookworm
  (checked 10 Nov 2026). They are WSJT-X 2.7.0, JS8Call 2.2.0 (ETC's 20.04
  build), SDR++ `sdrpp_debian_bookworm_amd64.deb` (nightly 1.3.2, unpinned as in
  r7), Pat 1.0.0, min 1.35.6, et-predict-app 1.5.2, et-aircraft-app 1.1.1,
  VeraCrypt 1.26.29 (Debian 12 build) and PFTE 15.0.8. Still to do: runtime
  checks, especially JS8Call and WSJT-X (launch, audio, CAT through et-radio).
  Fallbacks: Debian's own `js8call` 2.2.0 and `wsjtx` packages.
- The existing user (first-boot account) gets dialout and et-data access and
  the `/etc/skel` files after `install.sh`, after logging out and back in.
- Desktop parity: the dock shows the `favorite-apps` launchers, and
  `~/Desktop/offline` is visible on the desktop.
- wine 8.0: the VARA/Winlink add-on under `overlay/etc/skel/add-ons/wine` still
  works (r7 had wine 7.0).
- et-api starts on OpenJDK 17 (`http://localhost:1981/api/geo/position`).
  Spring Boot 2.4 predates official Java 17 support.
- No credentials or logs remain in an option 1 ISO.
- penguins-eggs on bookworm. Candidate pin: **v26.10.30** (`penguins-eggs_26.10.30-1_amd64.deb`).
  Static check, 10 Nov 2026:
  - All dependencies resolve on bookworm (`busybox-initramfs` is missing, but
    its alternative `busybox-static` is there).
  - The `oa` and `coa` binaries need glibc 2.34; bookworm has 2.36.
  - The bundled `bootloaders/grub/i386-pc/grub-bios-setup` needs glibc 2.38 and
    **won't run on bookworm**. It's likely only used by eggs' own installer for
    BIOS disk installs; Calamares uses Debian's GRUB. Confirm the ISO build
    doesn't call it.
  - Upstream doesn't list supported Debian versions, and the package appears to
    be built on trixie. Releases come out every few days, so keep the pin
    until a new version is tested.
  - Still to test in a bookworm VM: `eggs remaster`, `--clone`, `--crypted`, and
    whether `--crypted` includes the user's data (upstream calls it an
    "Encrypted Clone").
