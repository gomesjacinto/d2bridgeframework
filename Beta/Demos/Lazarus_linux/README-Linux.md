# Running D2Bridge on Linux (Lazarus / Debian 12)

This guide documents how to compile and run the D2Bridge Beta demo on Linux using Lazarus and FPC. Tested on **Debian 12** with **FPC 3.2.2** and **Lazarus 2.2.6**.

---

## Requirements

- Debian 12 (or compatible)
- FPC 3.2.2
- Lazarus 2.2.6
- Indy for Lazarus (manual install — not available in apt)
- Xvfb (virtual display for GTK2 backend)

---

## Step 1 — Install dependencies

```bash
apt-get update
apt-get install -y fpc lazarus lcl-utils-2.2 xvfb git
```

---

## Step 2 — Install Indy for Lazarus

Indy is not available in apt. Clone and register it manually:

```bash
git clone https://github.com/IndySockets/Indy.git /opt/indy
lazbuild --add-package-link /opt/indy/Lib/indylaz.lpk
lazbuild /opt/indy/Lib/indylaz.lpk
```

---

## Step 3 — Clone this repository

```bash
git clone https://github.com/gomesjacinto/d2bridgeframework.git /opt/d2bridge
```

---

## Step 4 — Fix script permissions

Git does not preserve execute permissions. Fix them before compiling:

```bash
chmod +x /opt/d2bridge/Beta/Demos/Lazarus_linux/FixD2BridgeLazCompile.sh
chmod +x /opt/d2bridge/Beta/Demos/Lazarus_linux/FixD2BridgeLazBuild.sh
```

---

## Step 5 — Compile the demo

```bash
cd /opt/d2bridge/Beta/Demos/Lazarus_linux
lazbuild --ws=gtk2 Lazarus.lpi
```

Expected output: `(1008) ~1049287 lines compiled` with no errors (warnings are normal).

---

## Step 6 — Start a virtual display

The GTK2 backend requires a display. Use Xvfb as a headless virtual display:

```bash
Xvfb :99 -screen 0 1024x768x24 &
```

---

## Step 7 — Run the server

```bash
cd /opt/d2bridge/Beta/Demos/Lazarus_linux/web
DISPLAY=:99 ./Lazarus
```

The server will prompt for port (default: **8888**) and server name. After confirming, access the app at:

```
http://<your-server-ip>:8888
```

Default credentials: `admin` / `admin`

---

## Running as a background service

```bash
Xvfb :99 -screen 0 1024x768x24 &>/var/log/xvfb.log &
cd /opt/d2bridge/Beta/Demos/Lazarus_linux/web
DISPLAY=:99 nohup ./Lazarus > /var/log/d2bridge.log 2>&1 &
```

---

## Tested environment

| Component | Version |
|---|---|
| OS | Debian 12.12 |
| Kernel | 6.17.2 |
| FPC | 3.2.2 |
| Lazarus | 2.2.6 |
| Indy | latest (GitHub) |

---

## Notes

- `Prism.ResourceMonitor.pas` Linux support is still in progress (tracked in this fork). This does not affect the demo functionality.
- The `nogui` widget set (`--ws=nogui`) causes an internal compiler exception in `Prism.Log.pas` — use `gtk2` + Xvfb instead.
- Tested on a Proxmox LXC (unprivileged container, Debian 12).
