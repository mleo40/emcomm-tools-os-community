# Building the EmComm Tools ISO

How to build your own EmComm Tools (ETC) ISO with Debian's live-build. The
result is Debian 12 with ETC, ready to use. Building needs internet; the ISO
doesn't.

In short: install Debian 12, clone this repository and run `sudo ./build.sh`,
run `ET_EXPERT=1 ./install.sh` and answer its questions, customize, then
`exit`.

## Setup

You need a build machine or VM (4+ CPUs, 4 GB RAM, 100 GB disk) with internet.

1. **Install Debian 12**, minimal:
   - Download an installer image from
     [debian.org/releases/bookworm/debian-installer](https://www.debian.org/releases/bookworm/debian-installer/)
     (the small `netinst` image is enough).
   - Boot your build machine or VM from it and start the install.
   - **Leave the root password empty**: the build needs your user to have
     `sudo`, and this is how you get it.
   - Under Software selection, **untick** both **Debian desktop environment**
     and **GNOME**: they aren't needed, and leaving them out makes the Debian
     install much faster. **Tick SSH server**, in case you need to log in or
     copy files from another computer.
   - When the install finishes, reboot your build machine into Debian.

2. **Get the repository:** log in to your build machine (at its console, or
   over SSH from another computer) and run:

   ```bash
   sudo apt install -y git
   git clone https://github.com/thetechprepper/emcomm-tools-os-community.git
   cd emcomm-tools-os-community
   git checkout <release tag or branch you want to build>
   ```

   To build the main branch, skip the `git checkout` line.

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
At the console, typing `exit` once more will log out; then log in again.

</details>

### Optional: the xara modem

xara is no longer distributed by its developer, so the build can't download
it. To include it, bring your own copy of its source code, packaged as described
in [scripts/xara.md](../scripts/xara.md). To get your copy onto the build
machine, copy it from another computer with `scp`. For example, from the
folder that contains `xara/`, using your login name and the build machine's
IP address (shown by `ip -4 addr` on the build machine):

```bash
scp -r xara youruser@192.168.1.50:~/
```

Then, on the build machine:

1. Package the source as `xara-VERSION.tar.gz` (e.g. `xara-0.1.3.tar.gz`),
   with a single top-level folder named `xara`
2. Copy the tarball into the repository's `scripts/` folder:

   ```bash
   tar -czf ~/xara-0.1.3.tar.gz -C ~ xara
   cp ~/xara-0.1.3.tar.gz ~/emcomm-tools-os-community/scripts/
   ```

## Build

1. **Start the build:**

   ```bash
   cd ~/emcomm-tools-os-community/live-build
   sudo ./build.sh
   ```

   First, `build.sh` uses Debian's live-build to create a fresh Debian 12
   system in a folder, downloading and installing its packages. This takes a
   while, so be patient; then the build's root shell is ready, in the same
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
   with `apt install`, add files, or change settings as you see fit.
   Everything done here ends up in your ISO.

4. **Type `exit`.** This leaves the shell and automatically starts making the
   ISO. This takes a while; be patient.

## Output

When the process finishes, it shows where the ISO is and how many `install.sh`
steps failed, if any. Both the ISO and the full log (`build.log`) are in
`/var/tmp/etc-live-build/`. If any steps failed, check them in `build.log`
before using the ISO.

### Copy the ISO off the build machine

One way to get the ISO off the build machine is `scp`: from another computer,
in the folder where you want the ISO, run this with your login name and the
build machine's IP address (shown by `ip -4 addr` on the build machine):

```bash
scp youruser@192.168.1.50:/var/tmp/etc-live-build/*.iso .
```

Or download it with a web browser. On the build machine, start Python's
built-in web server:

```bash
cd /var/tmp/etc-live-build && python3 -m http.server 8000
```

Then, on another computer, open `http://192.168.1.50:8000` in a browser and
click the ISO to download it. Press Ctrl+C on the build machine to stop the
server when you're done.

To install the ISO, see [INSTALL-GUIDE.md](INSTALL-GUIDE.md).

## What's in your ISO

Your ISO is your own build, with the choices you made while building it:

| Item | Details |
|---|---|
| Debian 12, GNOME, EmComm Tools | Installed |
| Map tiles, Navit map, Wikipedia (`.zim`) files, xara | Those chosen while building |
| Any additional customizations you've made | Included |
| VARA | Scripts and docs; added after install (see `scripts/wine.txt`) |
| GRUB for UEFI and BIOS | Carried, for offline installs |
| Live session | Starts the installer; closing it leaves the desktop. Login `user` / `live` (Debian's default); SSH off |
| This repository | Read-only copy in `/opt/emcomm-tools-os-community` |
| Accounts, SSH host keys, machine-id, logs | None; generated during the install |
