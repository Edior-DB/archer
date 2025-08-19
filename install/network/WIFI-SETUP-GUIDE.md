# Wi-Fi Setup Guide for Arch Linux Installation (archiso)

Before you can download and run any installation scripts (such as `install.sh`) on a fresh Arch Linux system, you must connect your machine to the internet. If you are using Wi-Fi, follow these steps from the default Arch ISO environment:

---

## 1. List Available Wi-Fi Devices

```bash
iwctl device list
```

Typical device names: `wlan0`, `wlp2s0`, etc.

---

## 2. Start the Interactive Wi-Fi Tool

```bash
iwctl
```

This will open the `iwctl` prompt.

---

## 3. Scan for Networks

Inside the `iwctl` prompt, run:

```
device list
station <device> scan
station <device> get-networks
```
Replace `<device>` with your Wi-Fi device name (e.g., `wlan0`).

---

## 4. Connect to Your Network

Still inside `iwctl`:

```
station <device> connect <SSID>
```
- Replace `<device>` with your Wi-Fi device name.
- Replace `<SSID>` with your network name.
- If prompted, enter your Wi-Fi password.

---

## 5. Verify Connection

Exit `iwctl` (type `exit`), then run:

```bash
ping archlinux.org
```
If you see replies, you are online.

---

## 6. Troubleshooting
- If you have issues, try rebooting or double-checking your SSID and password.
- For advanced troubleshooting, see the [Arch Wiki: Wireless](https://wiki.archlinux.org/title/Wireless_network_configuration).

---

## 7. Continue Installation

Once you have a working internet connection, you can proceed to download and run your installation script:

```bash
curl -O <your_install_script_url>
sh install.sh
```

---

**Tip:** If you are using a USB Wi-Fi dongle, make sure it is supported by the kernel included in the Arch ISO.

---

# References
- [Arch Wiki: Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Arch Wiki: Wireless](https://wiki.archlinux.org/title/Wireless_network_configuration)
