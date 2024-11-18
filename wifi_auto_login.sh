#!/bin/bash

# Configurable variables
LOG_FILE=~/wifi_auto_login.log
USERNAME="softwarica"
PASSWORD="cov3ntry123"
LOGIN_URL="http://gateway.example.com/"
CHROME_BINARY="/usr/bin/google-chrome"
MAX_RETRIES=3  # Maximum login retries
RETRY_DELAY=5  # Delay between retries in seconds

# Log setup
exec > >(tee -a "$LOG_FILE") 2>&1
echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - Starting Wi-Fi Auto Login Script..."

# Check if required tools are available
check_dependencies() {
    for cmd in curl "$CHROME_BINARY"; do
        if ! command -v $cmd &>/dev/null; then
            echo "❌ Error: Required tool '$cmd' is not installed."
            exit 1
        fi
    done
}

# Function to check internet connectivity
check_connection() {
    if ping -c 1 -W 2 google.com &>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ✅ Internet connection is active."
        return 0
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ No internet connection."
        return 1
    fi
}

# Function to validate inputs
validate_inputs() {
    if [[ -z "$USERNAME" || -z "$PASSWORD" || -z "$LOGIN_URL" ]]; then
        echo "❌ Error: Username, Password, and Login URL must be configured."
        exit 1
    fi
}

# Function to perform login via curl
perform_login() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Attempting to log in using curl..."
    RESPONSE=$(curl -s -X POST -d "username=$USERNAME&password=$PASSWORD" "$LOGIN_URL")
    if [[ "$RESPONSE" == *"successful"* ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ✅ Login successful!"
        return 0
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ Login failed. Response: $RESPONSE"
        return 1
    fi
}

# Function to run Google Chrome in headless mode
run_chrome_headless() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Opening Chrome in headless mode..."
    $CHROME_BINARY --headless --disable-gpu --dump-dom "$LOGIN_URL" \
        --run-all-compositor-stages-before-draw \
        --user-data-dir=/tmp/chrome-wifi-session \
        --disable-extensions >/dev/null 2>&1 &
}

# Main script logic
main() {
    check_dependencies
    validate_inputs

    if check_connection; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ✅ Internet already connected. Exiting script."
        exit 0
    fi

    for attempt in $(seq 1 $MAX_RETRIES); do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Login attempt $attempt of $MAX_RETRIES..."
        
        # Step 1: Open Chrome in headless mode
        run_chrome_headless
        sleep $RETRY_DELAY  # Wait for Chrome to load the page

        # Step 2: Perform login attempt via curl
        if perform_login; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking internet connectivity after login..."
            if check_connection; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - ✅ Login successful and internet is active!"
                exit 0
            fi
        fi

        echo "$(date '+%Y-%m-%d %H:%M:%S') - Retrying after $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ Login failed after $MAX_RETRIES attempts. Please check credentials or URL."
    exit 1
}

main
