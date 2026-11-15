# Building the EmComm Tools ISO

How to build your own EmComm Tools (ETC) ISO with Debian's live-build. The
result is Debian 12 with ETC installed, ready to install. Building needs
internet; the ISO doesn't.

In short: install Debian 12, clone this repository and run `sudo ./build.sh`,
run `ET_EXPERT=1 ./install.sh` and answer its questions, customize, then
`exit`.

## Setup

You need a build machine or VM (4+ CPUs, 4 GB RAM, 100 GB disk) with internet.

1. **Install Debian 12**, minimal:
   - Installer images:
     [debian.org/releases/bookworm/debian-installer](https://www.debian.org/releases/bookworm/debian-installer/)
     (the small `netinst` image is enough).
   - Under Software selection, untick both **Debian desktop environment** and
     **GNOME**: they aren't needed, and leaving them out makes the Debian
     install much faster.
   - **Leave the root password empty**: the build needs your user to have
     `sudo`, and this is how you get it.

2. **Get the repository:** once Debian is installed, log in to your build
   machine (at its console, in a terminal, or over SSH) and run:

   ```bash
   sudo apt install -y git
   git clone https://github.com/thetechprepper/emcomm-tools-os-community.git
   cd emcomm-tools-os-community
   git checkout <release tag or branch>
   ```

<details>
<summary>Only if <code>sudo</code> says you're not in the sudoers file</summary>

A root password was set during install. Fix it as root, using the root
password and your login name:

```bash
su -
apt install -y sudo git
adduser youruser sudo
exit
```

**Then log out and back in** (or reboot): `sudo` works only after a new login.

</details>

### Optional: the xara modem

xara is no longer distributed by its developer, so the build can't download
it. To include it, bring your own copy of its source code, packaged as described
in [scripts/xara.md](../scripts/xara.md):

1. Package the source as `xara-VERSION.tar.gz` (e.g. `xara-0.1.3.tar.gz`),
   with a single top-level folder named `xara`
2. Copy the tarball into the repository's `scripts/` folder:

   ```bash
   tar -czf ~/src/xara-0.1.3.tar.gz -C ~/src xara
   cp ~/src/xara-0.1.3.tar.gz ~/emcomm-tools-os-community/scripts/
   ```

## Build

1. **Start the build:**

   ```bash
   cd ~/emcomm-tools-os-community/live-build
   sudo ./build.sh
   ```

   First, `build.sh` uses Debian's live-build to create a fresh Debian 12
   system in a folder, downloading and installing its packages. This takes
   15 minutes or more; then the build's root shell is ready, in the same
   terminal.

2. **Install EmComm Tools:** when the build's root shell is ready, type the
   following and answer the ETC questions (Navit map, Wikipedia `.zim` file,
   map tiles):

   ```bash
   ET_EXPERT=1 ./install.sh
   ```

   `ET_EXPERT=1` turns on ETC's expert mode: it adds the Wikipedia question and
   shows how to add VARA after install. When it's done, it will show the next
   steps.

   A successful install ends like this:

   ```text
   === EmComm Tools installed ===
   Optional: cd ../tests && ./run-test-suite.sh
   Then type exit to make the ISO.

   (live)root@debian:/opt/emcomm-tools-os-community/scripts#
   ```

3. **Optional: customize.** In the build's root shell, install extra packages
   with `apt install`, add files, or change settings. Everything done there
   ends up in the ISO.

4. **Type `exit`.** This leaves the shell and automatically starts making the
   ISO. The whole build takes about 45 minutes.

## Output

When the build finishes, it shows where the ISO is and how many `install.sh`
steps failed, if any. Both the ISO and the full log (`build.log`) are in
`/var/tmp/etc-live-build/`. If any steps failed, check them in `build.log`
before using the ISO.

To install the ISO, see [INSTALL-GUIDE.md](INSTALL-GUIDE.md).

## What's in your ISO

Your ISO is your own build, with the choices you made while building it:

| Item | |
|---|---|
| Debian 12, GNOME, EmComm Tools | Installed |
| Map tiles, Navit map, Wikipedia (`.zim`) files, xara | Those chosen while building |
| Any additional customizations you've made | Included |
| VARA | Scripts and docs; added after install (see `scripts/wine.txt`) |
| GRUB for UEFI and BIOS | Carried, for offline installs |
| Live session | Starts the installer; closing it leaves the desktop. Login `user` / `live` (Debian's default); SSH off |
| This repository | Read-only copy in `/opt/emcomm-tools-os-community` |
| Accounts, SSH host keys, machine-id, logs | None; generated during the install |
