#!/bin/bash
# =========================================
# UPS Setup Wizard
# Multi-UPS Detection + Telegram Alerts
# =========================================

# --- Appearance ---
BLUE_BG=$(tput setab 4)
RESET=$(tput sgr0)

whiptail --title "Welcome to UPS Setup Wizard" \
         --yesno "This script will configure UPS monitoring on this system.\n\nWould you like to begin?" 12 60

[[ $? -ne 0 ]] && echo "User cancelled." && exit 0

clear
BLUE='\033[1;34m'
NC='\033[0m'
echo -e "${BLUE}"
echo "###############################################"
echo "#             UPS Setup                       #"
echo "###############################################"
echo -e "${NC}"

# --- Root Check ---
if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run as root."
  exit 1
fi

# --- Install Dependencies ---
apt update
apt install -y nut nut-client nut-server nut-scanner whiptail curl

# --- Mode Selection ---
MODE=$(whiptail --title "UPS Setup Mode" --menu "Select setup mode:" 15 60 3 \
"1" "UPS Server (connects USB UPS)" \
"2" "UPS Client (monitors a remote server)" 3>&1 1>&2 2>&3)

[[ $? -ne 0 ]] && echo "User exited." && exit 1
[[ "$MODE" == 1 ]] && INSTALL_MODE="server"
[[ "$MODE" == 2 ]] && INSTALL_MODE="client"

clear
echo -e "${BLUE}"
echo "############### Setting up: ${INSTALL_MODE^^} ###############"
echo -e "${NC}"
sleep 1

# ================================
# SERVER SETUP
# ================================
if [[ "$INSTALL_MODE" == "server" ]]; then
  echo "🔎 Scanning UPS devices using nut-scanner -U..."
  mkdir -p /opt/ups-setup
  UPS_LIST_FILE="/opt/ups-setup/ups_detected.list"
  > "$UPS_LIST_FILE"
  > /etc/nut/ups.conf

  UPS_INDEX=1
  UPSNAME=""

  nut-scanner -U | while read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" =~ ^\[.*\] ]]; then
      UPSNAME="ups$UPS_INDEX"
      echo "$UPSNAME" >> "$UPS_LIST_FILE"
      echo "[$UPSNAME]" >> /etc/nut/ups.conf
      UPS_INDEX=$((UPS_INDEX + 1))
    else
      echo "$line" >> /etc/nut/ups.conf
    fi
  done

  if [[ ! -s "$UPS_LIST_FILE" ]]; then
    whiptail --title "No UPS Found" --msgbox "❌ No UPS devices detected. Check cables and retry." 10 60
    exit 1
  fi

  echo "✅ UPS devices detected:"
  cat "$UPS_LIST_FILE"

  # nut.conf
  echo "MODE=netserver" > /etc/nut/nut.conf

  # upsd.conf
  echo "LISTEN 127.0.0.1" > /etc/nut/upsd.conf

  # upsd.users
  cat <<EOF > /etc/nut/upsd.users
[monuser]
  password = master
  actions = SET
  instcmds = ALL
  upsmon master
EOF

  # upsmon.conf
  > /etc/nut/upsmon.conf
  echo "RUN_AS_USER root" >> /etc/nut/upsmon.conf
  while read -r UPSNAME; do
    echo "MONITOR $UPSNAME@localhost 1 monuser master master" >> /etc/nut/upsmon.conf
  done < "$UPS_LIST_FILE"
fi

# ================================
# CLIENT SETUP
# ================================
if [[ "$INSTALL_MODE" == "client" ]]; then
  UPS_NAME=$(whiptail --inputbox "Enter UPS name (e.g. ups1):" 10 60 3>&1 1>&2 2>&3)
  UPS_USER=$(whiptail --inputbox "Enter Username:" 10 60 3>&1 1>&2 2>&3)
  UPS_PASS=$(whiptail --inputbox "Enter Password:" 10 60 3>&1 1>&2 2>&3)
  SERVER_IP=$(whiptail --inputbox "Enter Server IP address:" 10 60 3>&1 1>&2 2>&3)

  echo "MODE=netclient" > /etc/nut/nut.conf
  > /etc/nut/upsmon.conf
  echo "RUN_AS_USER root" >> /etc/nut/upsmon.conf
  echo "MONITOR $UPS_NAME@$SERVER_IP 1 $UPS_USER $UPS_PASS slave" >> /etc/nut/upsmon.conf
fi

# ================================
# NOTIFICATIONS & TELEGRAM SETUP
# ================================
cat <<EOF >> /etc/nut/upsmon.conf

NOTIFYCMD /usr/local/bin/ups-telegram-alert.sh
NOTIFYFLAG ONLINE SYSLOG+EXEC
NOTIFYFLAG ONBATT SYSLOG+EXEC
NOTIFYFLAG LOWBATT SYSLOG+EXEC
NOTIFYFLAG FSD SYSLOG+EXEC
NOTIFYFLAG COMMOK SYSLOG+EXEC
NOTIFYFLAG COMMBAD SYSLOG+EXEC
NOTIFYFLAG SHUTDOWN SYSLOG+EXEC
NOTIFYFLAG REPLBATT SYSLOG+EXEC
NOTIFYFLAG NOCOMM SYSLOG+EXEC
NOTIFYFLAG NOPARENT SYSLOG+EXEC
RBWARNTIME 43200
NOCOMMWARNTIME 600
FINALDELAY 5
EOF

# Setup Telegram
if whiptail --yesno "Enable Telegram alerts?" 10 60; then
  BOT_TOKEN=$(whiptail --inputbox "Enter Telegram Bot Token:" 10 60 3>&1 1>&2 2>&3)
  CHAT_ID=$(whiptail --inputbox "Enter Chat ID:" 10 60 3>&1 1>&2 2>&3)

  cat <<EOF > /usr/local/bin/ups-telegram-alert.sh
#!/bin/bash
CHAT_ID="$CHAT_ID"
BOT_TOKEN="$BOT_TOKEN"
NOW=\$(date +%r)
MESSAGE="UPS Notification %0ATime: \$NOW%0AUPS Name: \$UPSNAME%0ANotify type: \$NOTIFYTYPE"
curl -s \
  -d chat_id="\$CHAT_ID" \
  -d text="\$MESSAGE" \
  -d parse_mode=HTML \
  https://api.telegram.org/bot\$BOT_TOKEN/sendMessage > /dev/null
EOF

  chmod +x /usr/local/bin/ups-telegram-alert.sh
  touch /var/log/ups-alerts.log
  chmod 666 /var/log/ups-alerts.log
fi

# ================================
# ENABLE SERVICES
# ================================
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now nut-server nut-monitor

# ================================
# DONE + TROUBLESHOOTING
# ================================
clear
echo -e "${BLUE}"
echo "###############################################"
echo "#           UPS Setup Wizard Complete         #"
echo "#         Services started successfully       #"
echo "###############################################"
echo -e "${NC}"
echo ""
echo "Summary of key files changed:"
echo "  ➤ /etc/nut/nut.conf"
echo "  ➤ /etc/nut/ups.conf"
echo "  ➤ /etc/nut/upsd.conf"
echo "  ➤ /etc/nut/upsd.users"
echo "  ➤ /etc/nut/upsmon.conf"
echo "  ➤ /usr/local/bin/ups-telegram-alert.sh"
echo ""
echo "To test your UPS setup, run:"
echo "  ➤ upsc <ups_name>@localhost"
echo ""
echo "Troubleshooting Tips:"
echo "  - Use \"sudo systemctl status nut-server\" to check service health."
echo "  - Check /var/log/syslog for NUT logs."
echo "  - Run \"nut-scanner -U\" to rediscover UPSes."
echo ""
