#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input-file>" >&2
    exit 1
fi

INPUT_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Create log and password file with proper permissions
touch "$LOG_FILE"
chmod 600 "$PASSWORD_FILE"
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Function to log messages
log_message() {
    local MESSAGE="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $MESSAGE" >> "$LOG_FILE"
}

# Function to generate random password
generate_password() {
    echo "$(openssl rand -base64 12)"
}

# Read the input file line by line
while IFS=';' read -r USER GROUPS; do
    USER=$(echo "$USER" | xargs)
    GROUPS=$(echo "$GROUPS" | xargs | tr ',' ' ')

    # Check if the user already exists
    if id "$USER" &>/dev/null; then
        log_message "User $USER already exists. Skipping."
        continue
    fi

    # Create user's primary group
    if ! getent group "$USER" &>/dev/null; then
        groupadd "$USER"
        log_message "Group $USER created."
    fi

    # Create user with home directory
    useradd -m -g "$USER" "$USER"
    log_message "User $USER created with home directory /home/$USER."

    # Add user to additional groups
    for GROUP in $GROUPS; do
        if ! getent group "$GROUP" &>/dev/null; then
            groupadd "$GROUP"
            log_message "Group $GROUP created."
        fi
        usermod -aG "$GROUP" "$USER"
        log_message "User $USER added to group $GROUP."
    done

    # Generate a random password for the user
    PASSWORD=$(generate_password)
    echo "$USER,$PASSWORD" >> "$PASSWORD_FILE"
    echo "$USER:$PASSWORD" | chpasswd
    log_message "Password set for user $USER."

done < "$INPUT_FILE"

log_message "User creation script completed."

echo "Script execution completed. Check $LOG_FILE for details and $PASSWORD_FILE for user passwords."
