# Network UPS Tools (NUT) Setup Wizard

This script simplifies the setup and monitoring of UPS (Uninterruptible Power Supply) systems using Network UPS Tools (NUT). It supports both local (server) and remote (client) UPS monitoring, and optionally sends Telegram alerts when power events occur.

---
![License](https://img.shields.io/badge/license-MIT-blue)
![Language](https://img.shields.io/badge/language-Bash-brightgreen)

## 🚀 Features
- One-command install
- Auto-detect multiple USB UPS devices with `nut-scanner`
- Configure server or client monitoring modes
- Optional Telegram alerts for power events
- Automatic systemd integration
- Enables `nut-server` and `nut-monitor` on boot
- Creates and configures all required NUT config files:
  - `/etc/nut/nut.conf`
  - `/etc/nut/ups.conf`
  - `/etc/nut/upsd.conf`
  - `/etc/nut/upsd.users`
  - `/etc/nut/upsmon.conf`


---

## 🧰 Prerequisites
- Raspberry Pi or any Linux systems.

---

## 📦 Installation
```bash
curl -O https://raw.githubusercontent.com/KingBachin/nut-setup-wizard/main/ups-setup.sh
   ```
1. Make the script executable:
   ```bash
   sudo chmod +x ups-setup.sh
   ```

2. Run the script as root:
   ```bash
   sudo ./ups-setup.sh
   ```

3. Follow the prompts to:
   - Select mode (Server/Client)
   - Optionally set up Telegram alerts

---

## ✅ Test Commands
After installation, use the following to check UPS status:

```bash
sudo upsc ups1@localhost
```
```bash
sudo systemctl status nut-server
```
```bash
sudo systemctl status nut-client
```

---

## 📂 Sample Telegram Output
```
UPS Notification
Time: 10:42:03 PM
UPS Name: ups1
Notify type: COMMOK
```

---

## 🛠 Troubleshooting
- Check that the UPS is plugged in and powered on
- Run `nut-scanner -U` to verify detection
- Review logs in `/var/log/syslog` or use journalctl:
 ```bash
 sudo journalctl -u nut-server
  ```
 ```bash
 sudo journalctl -u nut-client
  ```
```bash
sudo systemctl restart nut-client
```
```bash
sudo systemctl restart nut-server
```
```bash
sudo systemctl restart nut-monitor
```

---

## ⚠️ Known Issues & Limitations

### 🟠 Identical UPS Models (Same Vendor/Product ID)

**Issue**  
If you connect two or more UPS units of the **exact same make and model**, they may share identical `vendorid` and `productid` values. This can cause the `usbhid-ups` driver to fail when trying to distinguish between devices.

**Symptoms**
- One or more UPS devices may **not start correctly**

**Why This Happens**  
NUT’s `usbhid-ups` driver uses the USB `vendorid`, `productid`, and sometimes the `serial` number to identify a device. When these values are the same across devices, the driver gets confused and fails to bind uniquely to each UPS.

---

### ✅ Workarounds

**Use Unique `port` Paths, Instead of relying on `port = auto`, manually specify the USB path for each UPS**
   
1. Find serials with:
```bash
sudo lsusb -v | grep -i serial
```

2. Edit nut.conf file:
```bash
sudo nano /etc/nut/nut.conf
```
 ```ini
 port = /dev/bus/usb/001/008
 serial = "ZNPXXXXXXX01"
```
Note: This is a known USB-level limitation, not a flaw in the script.

---

## 📜 License
MIT License. See `LICENSE` file for details.

