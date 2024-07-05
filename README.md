# HNG-Stage-2
## Automating User and Group Creation with a Bash Script
# Introduction:

Managing users and groups efficiently is a crucial task for SysOps engineers, especially in environments with a high turnover of employees. Automating this process saves time and reduces the potential for errors. This article will walk through a bash script named `create_users.sh.` This script reads a text file containing usernames and groups, creates the users and groups, sets up home directories, generates random passwords, and logs all actions. This solution is designed to meet the requirements of the HNG Internship program.

# Script Breakdown
Input File Format
The input file should contain the usernames and groups in the following format, where each line is formatted as user;groups:

````
Kotlin
 
light;sudo,dev,www-data
idimma;sudo
mayowa;dev,www-data
````
- `light` is the username.
- `sudo, dev, www-data` are the groups.
- 

### Script Structure

1. Check for Root Privileges: Ensure the script is run as the root user.
2. Read the Input File: Process the file line by line.
3. Create Users and Groups: Add users and groups as specified.
4. Setup Home Directories: Configure home directories with proper permissions.
5. Generate Passwords: Create random passwords for each user.
6. Logging: Log all actions and handle errors.

## Detailed Script Explanation
Here is the complete `create_users.sh` script with detailed comments:

```
#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Check if the input file is provided
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
```

### Usage Instructions
1. Ensure the Script is Run as Root:

- The script must be run with root privileges to perform user and group management tasks.

2. Provide the Input File:
- Run the script with the input file as an argument:

```
sudo bash create_users.sh <input-file>
```

3. Verify Log and Password Files:

Check `/var/log/user_management.log` for the log of actions performed.
Retrieve user passwords from `/var/secure/user_passwords.txt`.

# Example
Here's an example input file and the expected outcome after running the script:

Input File `(users.txt)`:

```
light;sudo,dev,www-data
idimma;sudo
mayowa;dev,www-data
```
Expected log Ouput:

```
2024-06-29 10:15:30 Group light created.
2024-06-29 10:15:30 User light created with home directory /home/light.
2024-06-29 10:15:30 Group sudo created.
2024-06-29 10:15:30 User light added to group sudo.
2024-06-29 10:15:30 Group dev created.
2024-06-29 10:15:30 User light added to group dev.
2024-06-29 10:15:30 Group www-data created.
2024-06-29 10:15:30 User light added to group www-data.
2024-06-29 10:15:30 Password set for user light.
...
```

Expected Password File Output (`/var/secure/user_passwords.txt`):
```
light,randompassword123
idimma,anotherpassword456
mayowa,yetanotherpassword789
```

### Diagrams
Flowchart of the Script Execution

```
graph TD;
    A[Start] --> B[Check for Root Privileges];
    B --> C{Is Root?};
    C -- No --> D[Exit with Error];
    C -- Yes --> E[Check for Input File];
    E --> F{Input File Provided?};
    F -- No --> G[Exit with Usage Message];
    F -- Yes --> H[Read Input File Line by Line];
    H --> I{User Exists?};
    I -- Yes --> J[Log and Skip User];
    I -- No --> K[Create User's Primary Group];
    K --> L[Create User with Home Directory];
    L --> M[Add User to Additional Groups];
    M --> N[Generate and Set Password];
    N --> O[Log Actions];
    O --> P[End];
```

### Error Handling
The script includes error handling for common scenarios:

Existing Users: If a user already exists, the script logs a message and skips to the next user.
Existing Groups: If a group already exists, the script skips the creation step for that group.
Input File Errors: The script checks if the input file is provided and exits with a usage message if not.
### Conclusion
This script automates the user and group creation process, making it efficient and error-free. It is a valuable tool for SysOps engineers managing multiple users. By following the steps outlined in this article, you can easily adapt the script to meet your specific needs.

### Links to HNG Internship
HNG Internship_(https://hng.tech)
</br>HNG Hire(www.hng.tech/hire)<br>

![image](https://github.com/cloudcraftswithsola/HNG-Stage-2/assets/89064868/afc7fb86-7a63-4acb-9280-ce8a122d2e0f)
