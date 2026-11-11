# Plan: EmComm Tools on Debian 12

Branch `feature/debian-base`, from tag `emcomm-tools-os-community-20261027-r7-build34`.

## Flow

An internet connection is needed for steps 1–3.

1. **Install Debian 12 (bookworm), amd64.**
   - Media: the standard Debian 12 installer (netinst or DVD).
   - Software selection: **GNOME** desktop.
   - Leave the **root password empty**, so the installer gives the first user
     `sudo`.
   - Reboot into the new system and log in as that user.

2. **Download EmComm Tools.**
   ```bash
   sudo apt update && sudo apt install -y git
   git clone -b feature/debian-base https://github.com/mleo40/emcomm-tools-os-community.git
   cd emcomm-tools-os-community/scripts
   ```
   Once this is merged, clone the release branch or tag instead.

3. **Install EmComm Tools.**
   ```bash
   sudo ./install.sh
   ```
   - Run it with `sudo` from your own account, not as root: it sets up the
     calling user (groups, home files).
   - Run it from `scripts/`, because the scripts use relative `../overlay` paths.
   - It takes a long time (source builds, map downloads). Progress is logged
     to `/tmp/et/et.log`.
   - Last step: *"Install optional encryption tools? [y/N]"* (default No).
     `ET_CRYPTO=yes|no` answers it in advance.

4. **Reboot.** That applies the new groups, `PATH`, boot splash and GNOME
   extensions. At the first login, ETC's user setup (callsign, grid and so on)
   opens.

5. **Optional: build an ISO.**
   ```bash
   sudo ./build-iso.sh
   ```
   It offers two kinds of ISO:

   - **Clean, shareable ISO:** build it right away, from a fresh install.
     Your accounts, home folder, Wi-Fi passwords, SSH keys, logs and other
     personal identifiers are removed. What's left is the stock EmComm Tools
     system, which you can hand to anyone. It boots as a live system, runs the
     first-login setup for whoever uses it, and can install itself to disk.
   - **Personal, portable ISO:** first set the system up the way you want it
     (callsign, radio and app settings, Winlink account, maps, messages,
     files), then build. The ISO is a copy of *your* system, with your account
     and data included, so you can carry it on a USB stick and boot your own
     setup on any machine. Because it contains your credentials and private
     data, treat the file like a password: don't share it. You can protect it
     with a passphrase (optional, default No).

   Either kind contains whatever software is installed, including the
   encryption tools if they were chosen. The output goes to `/home/eggs/`.
   Write it to a USB stick, for example with Ventoy; Ventoy's persistence
   option keeps your changes between boots.

## Changes

All script paths are under `scripts/` unless shown otherwise.

### Apt sources
- **`overlay/etc/apt/sources.list`**: point at Debian 12 (`deb.debian.org`
  bookworm, bookworm-updates, bookworm-security) with
  `main contrib non-free non-free-firmware`.
- **`overlay/etc/crontab`**: remove the `@reboot` line that copies
  `sources.list` from `/root/emcomm-tools-os-community/`. That path doesn't
  exist outside the Cubic build.

### Package swaps
- **`install-base.sh`**: `openjdk-20-jdk` → `openjdk-17-jdk` (see Java note).
- **`install-python.sh`**: `python2 python-setuptools` →
  `python3-setuptools python-is-python3`; remove the `update-alternatives`
  line that points `python` at python2. `install-mbutil.sh` (`python setup.py
  install`) then runs on python3 unchanged.
- **`install-wsjtx.sh`**: remove `libqcustomplot2.0` (not in bookworm, and not
  needed by the WSJT-X `.deb`).
- **`install-sdrpp.sh`**: download `sdrpp_debian_bookworm_amd64.deb` instead of
  `sdrpp_ubuntu_jammy_amd64.deb`.
- **`install-veracrypt.sh`**: download the `Debian-12` `.deb` instead of
  `Ubuntu-22.04`.
- **`remove-packages.sh`**:
  - drop `update-manager` and `update-notifier`: they aren't in Debian, and one
    unknown name makes the whole purge fail
  - add `firefox-esr`: r7 had no Firefox (Ubuntu's is a snap, removed with
    `snapd`), and nothing in ETC uses it
  - add `gnome-initial-setup`: Debian's first-login wizard. ETC has its own
    first-login setup, and location services stay off through the settings
    override
  - first mark the GNOME apps as manually installed: Debian's `gnome`
    metapackage hard-depends on LibreOffice, so the purge removes it and
    `apt autoremove` would otherwise strip the desktop apps too

### Removing Cubic and Ubuntu leftovers
- **`install-dev-tools.sh`**: remove the Cubic/PPA block.
- **`install-ubuntu-image-tools-only.sh`**: delete.
- **`debrand.sh`**:
  - install the Calamares branding instead of the Ubiquity slideshow (see Branding)
  - remove the kernel reinstall and `update-initramfs` block
- **`install-branding.sh`**:
  - remove the `ubuntu-logo.png`, `warty-final-ubuntu.png` and Ubiquity
    pixmap steps
  - run `plymouth-set-default-theme -R bgrt` (r7's theme; Debian defaults to
    its own desktop-base theme)
  - add `splash` to `GRUB_CMDLINE_LINUX_DEFAULT` and run `update-grub`

### Desktop (GNOME)
- **`overlay/usr/share/glib-2.0/schemas/90_ubuntu-settings.gschema.override`**:
  rename to `90_emcomm-tools.gschema.override`; remove the
  `apps/update-manager` and `com/ubuntu/update-notifier` sections; enable the
  three extensions below and set the dock layout; add Ubuntu's
  minimize/maximize/close window buttons (GNOME's default is close only).
- **`configure-gnome.sh`**:
  - use the renamed override
  - install the Yaru theme: `yaru-theme-gtk yaru-theme-icon yaru-theme-gnome-shell`
  - install and enable the extensions Ubuntu builds in, so the desktop looks
    the same:

    | Extension | Gives |
    |---|---|
    | `gnome-shell-extension-dashtodock` | The always-visible dock with the ETC launchers (left side, fixed, full height) |
    | `gnome-shell-extension-desktop-icons-ng` | Icons on the desktop, including `~/Desktop/offline` |
    | `gnome-shell-extension-appindicator` | Tray icons |

### User setup
- **`configure-user.sh`**: create the `et-data` group only if it doesn't exist
  yet, so `install.sh` can be re-run.
- **New `configure-existing-user.sh`**, run last by `install.sh` (after every
  script has added to `/etc/skel`). The first user now exists *before*
  `install.sh` runs, so it sets up that user (`$SUDO_USER`):
  - copy `/etc/skel` into their home without overwriting, and chown it
  - set their primary group to `et-data` (GID 1981)
  - add them to the `EXTRA_GROUPS` from `adduser.conf` (`dialout`,
    `bluetooth` and the rest)

  Without this, the user has no radio/serial access and is missing ETC's home
  files, including Reticulum.
- **New `overlay/etc/profile.d/emcomm-tools.sh`** (installed by
  `install-base.sh`): adds `/opt/emcomm-tools/bin:/usr/local/sbin:/usr/sbin:/sbin`
  to `PATH`. Debian's `/etc/profile` resets `PATH` and drops what
  `/etc/environment` sets (Ubuntu's doesn't), so the `et-*` commands wouldn't
  be found. No other `PATH` change is needed.

### Encryption opt-in
- **`install.sh`**: remove `install-gpa.sh`, `install-pfte.sh` and the
  VeraCrypt line; add the encryption prompt as the last step.
- **`install-base.sh`**: move `steghide` and `gpg` to `install-crypto.sh`.
- **`install-offline-lib.json`**: move the AmRRON `.asc` key and GPG guide
  entries to `install-crypto.sh`.

### Docs
- **`README.md`**, **`RELEASES.md`**: document the new flow.

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
  `cd /opt/emcomm-tools/add-ons/crypto/scripts && sudo ./install-crypto.sh`.
- The guides live in `scripts/crypto-docs/` (moved from
  `overlay/etc/skel/Desktop/offline/crypto/`); the AmRRON entries live in
  `scripts/install-offline-lib-crypto.json`.
- `gpg` itself stays on every system, because GNOME's Passwords and Keys app
  (`seahorse`) depends on `gnupg`. The opt-in covers ETC's explicit install and
  the guides.
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
| Live username and password | eggs' default for now (shown when eggs runs); setting ETC's own is still to do, once eggs' `custom.yaml` keys are confirmed in the VM | the user's own |
| Groups for users Calamares creates | `et-data`, `adduser.conf`'s `EXTRA_GROUPS` and `sudo`, as supplementary groups, through an eggs Calamares override (`/etc/penguins-eggs.d/branding/calamares/modules/users.conf`). Calamares uses `useradd`, which ignores `adduser.conf` | unchanged from the source system |
| How things are left out | a marked block in eggs' `custom.exclude.list`: Wi-Fi connections, SSH host keys, logs, `/tmp/et`. A new `et-ssh-keygen.service` creates SSH host keys on first boot when they're missing | the marked block is removed |
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
   version** (its CLI changed from `eggs produce` to `eggs remaster`), plus
   `calamares`, `cryptsetup` and `cryptsetup-initramfs`. Debian's GNOME install
   doesn't include `cryptsetup`, and both the Calamares encryption checkbox and
   `--crypted` need it.
2. Clean up as in the table, then run `eggs remaster` with the right flags.
   The output goes to `/home/eggs/`.
3. The ISO boots to a live GNOME session with an "Install" launcher for
   Calamares. Changes are lost on reboot unless the stick uses Ventoy
   persistence. Expect several GB (more with `ET_EXPERT`), so target USB.

## Branding

Same EmComm Tools branding as r7, moved from Ubuntu's mechanisms to Debian's:

| Item | r7 (Ubuntu) | Debian |
|---|---|---|
| Boot splash | Plymouth `bgrt` theme (Ubuntu's default), which draws the ETC throbber, animation and watermark PNGs that r7 copies into `themes/spinner/` | Same files, same theme: Debian's `bgrt` also reads `themes/spinner/`. Set it with `plymouth-set-default-theme -R bgrt`; `splash` on the kernel command line |
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
- `scripts/configure-existing-user.sh`
- `scripts/install-offline-lib-crypto.json`
- `overlay/etc/profile.d/emcomm-tools.sh`
- Calamares branding in `overlay/etc/calamares/branding/emcomm-tools/`:
  `branding.desc`, `show.qml`, `logo.png` (screenshots and background moved, not new)

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
- In a new terminal after logging in, `echo $PATH` includes
  `/opt/emcomm-tools/bin` and `which et-radio` finds it.
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
