# Building the EmComm Tools ISO

How to build your own EmComm Tools (ETC) ISO with Debian's live-build. The
result is Debian 12 with ETC, ready to use. Building needs internet; the ISO
doesn't.

## Setup

1. **Install Debian 12** on a build machine or VM (4+ CPUs, 4 GB RAM, 100 GB
   disk) with internet, minimal:
   - Download an installer image from
     [debian.org/releases/bookworm/debian-installer](https://www.debian.org/releases/bookworm/debian-installer/)
     (the small `netinst` image is enough).
   - Boot your build machine or VM from it and start the install.
   - **Leave the root password empty**, so your user gets `sudo`.
   - Under Software selection, **untick** **Debian desktop environment** and
     **GNOME** (not needed, and faster). **Tick SSH server** (for copying
     files later).
   - When the install finishes, reboot your build machine into Debian.

2. **Get the repository:** log in to your build machine (at its console, or
   over SSH from another computer) and run:

   ```bash
   sudo apt install -y git
   git clone https://github.com/thetechprepper/emcomm-tools-os-community.git
   cd emcomm-tools-os-community
   git checkout <release tag or branch you want to build>   # skip to build main
   ```

<details>
<summary>Only if <code>sudo</code> says you're not in the sudoers file</summary>

A root password was set during install. Fix it as root:

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

   It sets up a fresh Debian 12 system (this takes a while; be patient), then
   opens the build's root shell in the same terminal.

2. **Install EmComm Tools:** in the build's root shell, type the following and
   answer the ETC questions (Navit map, Wikipedia `.zim` file, map tiles).
   `ET_EXPERT=1` adds the Wikipedia question and the VARA notes.

   ```bash
   ET_EXPERT=1 ./install.sh
   ```

   A successful install ends with the next steps:

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

The ISO and the full log (`build.log`) are in `/var/tmp/etc-live-build/`. If
the build reports failed `install.sh` steps, check them in `build.log` before
using the ISO.

### Copy the ISO off the build machine

From another computer, use your login name and the build machine's IP address
(shown by `ip -4 addr` on the build machine). Either copy it with `scp`, in the
folder where you want the ISO:

```bash
scp youruser@192.168.1.50:/var/tmp/etc-live-build/*.iso .
```

Or download it with a web browser: on the build machine, run

```bash
cd /var/tmp/etc-live-build && python3 -m http.server 8000
```

then open `http://192.168.1.50:8000` on the other computer and click the ISO.
Press Ctrl+C on the build machine when you're done.

To install the ISO, see [INSTALL-GUIDE.md](INSTALL-GUIDE.md).

## What's in your ISO

Your ISO is your own build, with the choices you made while building it:

| Item | Details |
|---|---|
| Debian 12, GNOME, EmComm Tools | Installed |
| Map tiles, Navit map, Wikipedia (`.zim`) files, xara | Those chosen while building |
| Any additional customizations you've made | Included |
| VARA | Scripts and docs; added after install (see `scripts/wine.txt`) |
| Live session | Starts the installer; closing it leaves the desktop. Login `user` / `live` (Debian's default); SSH off |
