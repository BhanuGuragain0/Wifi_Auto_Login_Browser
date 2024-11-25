#!/bin/bash

# Colors and formatting
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

# Log file for errors
LOG_FILE="wifi_auto_login.log"

# Check prerequisites
for cmd in nmcli curl qrencode; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}Error: ${cmd} is not installed. Please install it first.${RESET}"
    exit 1
  fi
done

# Progress animation
show_progress() {
  echo -n "${CYAN}Processing"
  for i in {1..3}; do
    echo -n "."
    sleep 0.5
  done
  echo -e "${RESET}"
}

# Display system and user info
display_system_info() {
  echo -e "${YELLOW}User: ${CYAN}$(whoami)${RESET}"
  echo -e "${YELLOW}OS: ${CYAN}$(uname -o) $(lsb_release -ds)${RESET}"
  echo -e "${YELLOW}System uptime: ${CYAN}$(uptime -p)${RESET}"
}

# Check current Wi-Fi connection
check_wifi_connection() {
  CURRENT_SSID=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d':' -f2)

  if [[ -n "$CURRENT_SSID" ]]; then
    echo -e "${GREEN}Currently connected to Wi-Fi: $CURRENT_SSID${RESET}"
    show_wifi_qr "$CURRENT_SSID"
    return 0
  else
    echo -e "${RED}No active Wi-Fi connection.${RESET}"
    return 1
  fi
}

# Connect to the strongest Wi-Fi network
connect_wifi() {
  echo -e "${CYAN}Scanning for available Wi-Fi networks...${RESET}"
  SSID=$(nmcli -t -f SSID,SIGNAL dev wifi | sort -t: -k2 -nr | head -n 1 | cut -d: -f1)

  if [[ -z "$SSID" ]]; then
    echo -e "${RED}No Wi-Fi networks found!${RESET}"
    exit 1
  fi

  echo -e "${GREEN}Connecting to Wi-Fi: $SSID...${RESET}"
  if ! nmcli dev wifi connect "$SSID"; then
    echo -e "${RED}Failed to connect to $SSID.${RESET}" | tee -a "$LOG_FILE"
    exit 1
  fi

  echo -e "${GREEN}Connected successfully to $SSID.${RESET}"
  show_wifi_qr "$SSID"
}

# Generate QR code for Wi-Fi
show_wifi_qr() {
  local SSID=$1
  echo -e "${CYAN}Generating QR code for Wi-Fi: $SSID...${RESET}"
  QR_CONTENT="WIFI:S:$SSID;T:WPA;P:your_password;;"
  qrencode -t ANSIUTF8 "$QR_CONTENT"
}

# Handle captive portal login
login_portal() {
  echo -e "${CYAN}Checking for captive portal...${RESET}"
  PORTAL_URL=$(curl -s http://connectivity-check.ubuntu.com | grep -oP 'http://[^"]+')

  if [[ -z "$PORTAL_URL" ]]; then
    echo -e "${GREEN}No captive portal detected.${RESET}"
    return
  fi

  echo -e "${YELLOW}Captive portal detected at $PORTAL_URL${RESET}"
  echo -e "${CYAN}Attempting automated login...${RESET}"

  curl -s -d "username=softwarica&password=cov3ntry123" "$PORTAL_URL" >/dev/null
  echo -e "${GREEN}Login attempt completed.${RESET}"
}

verify_connection() {
  echo -e "${CYAN}Verifying internet connection...${RESET}"
  if ping -c 3 google.com &>/dev/null; then
    echo -e "${GREEN}Internet connection verified!${RESET}"
  else
    echo -e "${RED}Internet connection verification failed.${RESET}" | tee -a "$LOG_FILE"
    exit 1
  fi
}


# Main execution
clear
echo -e "${CYAN}=== Wi-Fi Auto Login Script ===${RESET}"
display_system_info

if ! check_wifi_connection; then
  connect_wifi
fi

login_portal
verify_connection
