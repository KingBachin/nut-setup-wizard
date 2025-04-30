# ups-setup-wizard
Auto-detect and configure Network UPS Tools (NUT) with multi-UPS support, Telegram alerts, and server/client modes — perfect for Raspberry Pi and Linux systems.

This script simplifies the setup and monitoring of UPS (Uninterruptible Power Supply) systems using Network UPS Tools (NUT). It supports both local (server) and remote (client) UPS monitoring, and optionally sends Telegram alerts when power events occur.

---

## 🚀 Features
- Prompt for guided setup
- Auto-detects multiple connected UPS devices using `nut-scanner`
- Creates and configures all required NUT config files:
  - `/etc/nut/nut.conf`
  - `/etc/nut/ups.conf`
  - `/etc/nut/upsd.conf`
  - `/etc/nut/upsd.users`
  - `/etc/nut/upsmon.conf`
- Optional Telegram notification integration via bot token and chat ID
- Enables `nut-server` and `nut-monitor` on boot

---

## 🧰 Prerequisites
- Debian or Ubuntu-based system

---

## 📦 Installation
1. Make the script executable:
   ```bash
   chmod +x ups-setup.sh
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
upsc ups1@localhost
```
 ```bash
 sudo journalctl -u nut-server
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
- Run `nut-scanner -U` manually to verify detection
- Review logs in `/var/log/syslog` or use journalctl:
```bash
sudo service nut-server restart
```
```bash
sudo service nut-client restart
```
```bash
sudo systemctl restart nut-monitor
```

---

## 📜 License
MIT License. See `LICENSE` file for details.

