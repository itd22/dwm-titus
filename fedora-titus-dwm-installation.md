# Fedora Titus DWM installation

Details on Anaconda installer "Software Selection" HWOTO configure the Installation Source.
custom dwm-titus installer ISO installs a minimal, working dwm session.
It covers common cases when using the provided dwm-titus ISO in VirtualBox.

Goal
- Install a minimal Fedora system able to run dwm built from the dwm-titus repo.
- Avoid unnecessary packages while keeping the X11 stack and build/runtime deps needed by dwm.

Quick recommendation
- If you only have the dwm-titus ISO built from a netinst image and do not want to use the internet during install: run a simple HTTP server on your host that serves a full Fedora DVD tree (or the host-mounted ISO) and point the VM/installer at that URL (NAT: `http://10.0.2.2:8000/`). See steps below.

1) Verify the ISO type (netinst/live vs DVD/Everything)
- On your host (Linux):
  - sudo mkdir -p /mnt/fiso
  - sudo mount -o loop path/to/dwm-titus.iso /mnt/fiso
  - ls /mnt/fiso
    - If you see `Packages/` and `repodata/` in the top-level listing, this is a full/DVD image (offline-capable).
    - If you see `LiveOS/` or no `Packages/`/`repodata/`, it is a live or netinst image (installer will fetch packages from the network by default).

2) VirtualBox basics
- VM settings → Storage → Attach the `dwm-titus.iso` to the virtual optical drive.
- VM network: NAT is simplest. With NAT the host is reachable from the guest at `10.0.2.2` (useful if you host a local HTTP server).
- Boot the VM and select the Fedora installer entry.

3) Installation Source (what to choose in the installer)
- If ISO is netinst/live (no `repodata/`) and you do not want the installer to talk to the public internet:
  - Option A — Serve a full DVD tree from the host and point installer to it:
    - On host (mount a full Fedora DVD or the ISO that contains `Packages/repodata`):
      - sudo mount -o loop /path/to/Fedora-DVD.iso /mnt/fedoradvd
      - cd /mnt/fedoradvd
      - python3 -m http.server 8000 --bind 0.0.0.0
    - In the VM installer: Installation Source → On the network → URL: `http://10.0.2.2:8000/`
    - Installer will read `repodata/` and use those packages instead of reaching out to public mirrors.
  - Option B — Allow the installer to use the network (easiest if you do not need strict offline): leave default network repos enabled. The dwm-titus Kickstart already enables Fedora and RPM Fusion metalinks.

4) Software Selection (make these choices for a minimal dwm system)
- Base environment: choose "Minimal Install" (this provides the smallest base system). Then add the X11 bits and minimal build/runtime packages.
- Add the X/graphical groups or the following packages (group names and package availability depend on Fedora version):
  - Group: `@base-x` (or manually select the X packages below)
  - Packages to include (explicit list you can add):
    - xorg-x11-server-Xorg
    - xorg-x11-xinit
    - xrandr
    - xset
    - xsetroot
    - dbus-x11
    - xorg-x11-drv-libinput
  - Minimal runtime & build tools (required to build dwm from the repo):
    - gcc
    - make
    - pkgconf-pkg-config
    - git
    - curl
  - dwm runtime helpers & common desktop tools (optional but useful):
    - xclip, xdotool, xprop, feh, picom, alacritty or kitty
- If the installer exposes a "Customize now" or checkboxes for add-ons, make sure the above packages/groups are selected before continuing.

Why these choices
- "Minimal Install" keeps the system small; X11 packages provide the windowing system that dwm needs (`@base-x` contains X and fonts).
- Build tools (gcc, make) are needed if you plan to compile dwm during or after install (the dwm-titus ISO embeds the repo so post-install steps can build it).

5) Installation type / Disk partitioning
- For simplicity let Anaconda handle automatic partitioning (automatic partitioning with default LVM is fine).
- If you need custom partitions (LVM layout, encrypted root), use the manual partitioning screen and ensure `/boot` and `/` are created appropriately.

6) Embedded dwm-titus repo and Kickstart behavior
- The dwm-titus ISO embeds this repository and a Kickstart. During install the embedded checkout is exposed at `/run/install/repo/dwm-titus` in the installer environment.
- The Kickstart (`dwm-fedora.ks`) includes network repo metalinks by default. If you want the installer to *not* use the network, you must ensure the package repository the installer uses is the local DVD tree or a local HTTP server as described in step 3.
- After the base packages are installed you can open a shell in the installer (Troubleshooting → Shell) and inspect `/run/install/repo/dwm-titus` to run the included installer scripts manually or to chroot into the new system for additional build steps.

7) Post-install steps (make dwm-titus the active session)
- If Kickstart ran and installed all packages listed in the dwm-fedora.ks `%packages`, the system may still need the dwm binaries built/installed (depends on what the ISO/Kickstart package list included).
- Typical manual post-install flow (from the installed system or from a chroot during `%post`):
  - If not present on disk, clone or copy the embedded repo:
    - git clone https://github.com/ChrisTitusTech/dwm-titus.git /opt/dwm-titus
  - cd /opt/dwm-titus
  - make
  - sudo make install
  - Install a display manager or configure `.xinitrc` to start dwm. The repo provides `dwm.desktop` and LightDM integration if you selected LightDM packages.

8) VirtualBox-specific tips
- If you host an HTTP server on the host and the VM uses NAT, use `http://10.0.2.2:8000/` as the network repo URL in the installer.
- If using Host-only or Bridged, use the host IP on that network instead of `10.0.2.2`.
- If the installer can’t find the repository at the URL: confirm the host server is running and the host firewall allows the port.

9) Troubleshooting
- Installer says "No repository found" when you point to `file:///` or `http://`:
  - Confirm `repodata/` is at the top level of the served path (e.g., `http://10.0.2.2:8000/repodata/` exists).
  - If using `file://` and Anaconda cannot see the media, try the HTTP method instead.
- If the Software Selection UI hides package groups: choose "Minimal Install" then enable "Customize now" and explicitly add `@base-x` or the packages listed above.
- If you want the Kickstart to perform everything automatically, boot the ISO entry that applies the Kickstart (the project build script usually installs a boot menu entry that uses the embedded Kickstart). The Kickstart will install the packages it defines and then expose the repo at `/run/install/repo/dwm-titus` for any scripted post-install steps.

10) Minimal package checklist (copy/paste to the installer’s package add dialog or Kickstart)
- xorg-x11-server-Xorg
- xorg-x11-xinit
- xrandr
- xset
- xsetroot
- dbus-x11
- xorg-x11-drv-libinput
- gcc
- make
- pkgconf-pkg-config
- git
- curl
- lightdm (optional; choose if you want a greeter and session chooser)
- alacritty or kitty (terminal of choice)

Summary
- Best offline experience: use a DVD/Everything ISO (or rebuild the dwm-titus ISO with a DVD as input). In that case choose "Local media" as the Installation Source and set Software Selection to "Minimal Install" + `@base-x` (or the explicit package list above).
- If your dwm-titus ISO is netinst-based, serve a full DVD tree from the host via HTTP and point Anaconda to `http://10.0.2.2:8000/` (or allow network access to Fedora mirrors and let the Kickstart use metalinks by default).

If you want, I can:
- Create a Kickstart snippet that selects the minimal package list above.
- Give the exact commands to host the DVD tree from your host and the exact URL to paste into the installer.

---
Generated for ChrisTitusTech/dwm-titus.
