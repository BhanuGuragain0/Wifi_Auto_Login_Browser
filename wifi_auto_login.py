import os
import requests
from bs4 import BeautifulSoup
from urllib.parse import quote
from datetime import datetime
import pyqrcode
from termcolor import cprint
import time
import sys

# WiFi Credentials
USERNAME = "softwarica"
PASSWORD = "cov3ntry123"

# Portal URLs
AGREE_PAGE_URL = "http://gateway.example.com/no_cookie_loginpages/"
LOGIN_PAGE_URL = "http://gateway.example.com/loginpages/"
PING_URL = "https://www.google.com"

# Colorful log function
def log(message, color="green"):
    cprint(f"[{datetime.now().strftime('%H:%M:%S')}] {message}", color)

# Check internet connection
def check_internet():
    try:
        response = requests.get(PING_URL, timeout=5)
        if response.status_code == 200:
            return True
    except requests.RequestException:
        return False
    return False

# Generate and display WiFi QR code
def show_wifi_qr(ssid="STWCU_LR", password="cov3ntry123"):
    log("Generating WiFi QR code...", "blue")
    qr_content = f"WIFI:T:WPA;S:{ssid};P:{password};;"
    qr_code = pyqrcode.create(qr_content)
    print(qr_code.terminal())

# Attempt to navigate the portal
def login_to_wifi():
    log("Checking for Agree Page...", "yellow")
    try:
        session = requests.Session()
        agree_response = session.get(AGREE_PAGE_URL, timeout=5)
        
        # Check if Agree Page is displayed
        if agree_response.status_code == 200:
            log("Agree Page found. Accepting terms...", "cyan")
            soup = BeautifulSoup(agree_response.content, "html.parser")
            form = soup.find("form")
            
            if form:
                action_url = form.get("action")
                data = {input_tag.get("name"): input_tag.get("value", "") for input_tag in form.find_all("input")}
                session.post(action_url, data=data)
            log("Terms accepted.", "green")
        
        # Proceed to login page
        log("Navigating to Login Page...", "yellow")
        login_response = session.get(LOGIN_PAGE_URL, timeout=5)
        if login_response.status_code == 200:
            soup = BeautifulSoup(login_response.content, "html.parser")
            form = soup.find("form")
            
            if form:
                action_url = form.get("action")
                data = {
                    "username": USERNAME,
                    "password": PASSWORD
                }
                # Add any hidden fields from the login form
                for input_tag in form.find_all("input"):
                    if input_tag.get("type") == "hidden":
                        data[input_tag.get("name")] = input_tag.get("value", "")
                login_result = session.post(action_url, data=data)
                if "Hello, you are logged in via softwarica" in login_result.text:
                    log("Successfully logged in!", "green")
                    return True
        else:
            log("Unable to access the login page.", "red")
    except Exception as e:
        log(f"Error occurred: {e}", "red")
    return False

# Display system info
def display_system_info():
    log("Fetching system info...", "yellow")
    uptime = os.popen("uptime -p").read().strip()
    kernel = os.popen("uname -r").read().strip()
    user = os.getlogin()
    log(f"System User: {user}")
    log(f"System Uptime: {uptime}")
    log(f"Kernel Version: {kernel}")

# Main function
def main():
    os.system("clear")
    log("Starting WiFi Auto Login Script...", "cyan")
    
    # Step 1: Check internet connection
    log("Checking internet connectivity...", "yellow")
    if check_internet():
        log("Internet is already connected.", "green")
        show_wifi_qr()
        return
    
    # Step 2: Attempt to login to WiFi
    log("Internet not connected. Proceeding to login...", "yellow")
    if login_to_wifi():
        if check_internet():
            log("Internet successfully connected.", "green")
            show_wifi_qr()
        else:
            log("Login successful, but no internet connectivity. Please check manually.", "red")
    else:
        log("Failed to log in to the WiFi portal.", "red")
    
    # Step 3: Display system info
    display_system_info()

if __name__ == "__main__":
    main()
