#!/bin/bash

# Enables immediate exit on error and sets a custom error trap
# so that any error will print a message before exiting
sct_enable_global_errors_handling() {
    set -e
    trap 'echo "An error occurred. Exiting..."; exit 1' ERR
}

# Check if the current script runs as root
sct_script_must_run_as_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script as root"
        exit 1
    fi
}

# Verify the specified user exists or fail with a custom error message
# Usage: sct_user_must_exist "username" "Custom error message"
sct_user_must_exist() {
    local username="$1"
    local message="$2"
    if ! id -u "$username" > /dev/null 2>&1; then
        echo "ERROR: User '$username' does not exist. $message"
        exit 1
    fi
}

# Setup swap file if not present, with configurable size (e.g., 2G, 2048M)
# Usage: sct_setup_swap 2G or sct_setup_swap 2048M
sct_setup_swap_if_not_enabled() {
    local swap_size="$1"
    if [ -z "$swap_size" ]; then
        echo "Usage: sct_setup_swap <size> (e.g., 2G or 2048M)"
        return 1
    fi
    if ! swapon --show | grep -q '^'; then
        echo "No swap found. Creating swap file of size $swap_size..."
        fallocate -l "$swap_size" /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=$(echo "$swap_size" | grep -oE '[0-9]+')
        chmod 600 /swapfile
        mkswap /swapfile > /dev/null
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        echo "Swap created and enabled."
    fi
}

# Install Docker CE if not already installed
sct_install_docker_if_not_exists() {
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker CE..."
        apt-get update > /dev/null
        apt-get install -y ca-certificates curl gnupg lsb-release > /dev/null
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update > /dev/null
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null
        echo "Docker CE installation complete. Version: $(docker --version)"
    fi
}

# Create and setup a SFTP user
# important: The SFTP root folder must exist and be owned by root
# Usage: sct_create_and_setup_sftp_user "username" "password" "group" "sftp_root_folder"
sct_create_and_setup_sftp_user() {
    local USERNAME="$1"
    local USER_PASSWORD="$2"
    local USER_GROUP="$3"
    local SFTP_ROOT_FOLDER="$4"

    # Validate input parameters
    if [ -z "$USERNAME" ] || [ -z "$USER_PASSWORD" ] || [ -z "$USER_GROUP" ] || [ -z "$SFTP_ROOT_FOLDER" ]; then
        echo "Usage: sct_create_and_setup_sftp_user <username> <password> <group> <sftp_root_folder>"
        return 1
    fi
    
    # Ensure SFTP_ROOT_FOLDER folder exists and is owned by root
    if [ ! -d "$SFTP_ROOT_FOLDER" ] || [ "$(stat -c '%U' "$SFTP_ROOT_FOLDER")" != "root" ]; then
        echo "ERROR: SFTP root folder '$SFTP_ROOT_FOLDER' must exist and be owned by root."
        return 1
    fi
    
    echo "Setting up SFTP user '$USERNAME:$USER_GROUP' with sftp root folder '$SFTP_ROOT_FOLDER'..."
    
    # Create group if it does not exist
    if ! getent group "$USER_GROUP" > /dev/null; then
        groupadd "$USER_GROUP" > /dev/null
    fi
    
    # Create user if it does not exist
    if ! id -u "$USERNAME" >/dev/null 2>&1; then
        adduser --system --ingroup "$USER_GROUP" --shell=/usr/sbin/nologin "$USERNAME" > /dev/null
    else
        echo "ERROR: User '$USERNAME' already exists."
        return 1
    fi

    # Set user password
    echo "$USERNAME:$USER_PASSWORD" | chpasswd > /dev/null
    
    # Configure SFTP access in sshd_config file
    local sftp_config="    
Match User $USERNAME
    ForceCommand internal-sftp
    ChrootDirectory $SFTP_ROOT_FOLDER
    PasswordAuthentication yes
    PermitTTY no
    X11Forwarding no
    AllowTcpForwarding no
    AllowAgentForwarding no"

    if ! grep -q "Match User $USERNAME" /etc/ssh/sshd_config; then
        echo "$sftp_config" >> /etc/ssh/sshd_config
        systemctl restart ssh
    fi
    
    echo "User sftp '$USERNAME' created successfully."
}

# Prompt the user for a variable (empty input is not allowed)
# Usage: USERNAME=$(sct_prompt_for_variable "message")
sct_prompt_for_variable() {
    local prompt_message="$1"
    local user_input

    read -p "$prompt_message:" user_input
    if [ -z "$user_input" ]; then
        echo "ERROR: Input cannot be empty."
        return 1
    fi
    echo "$user_input"
}

# Prompt the user for a variable or return a default value if input is empty
# Usage: USERNAME=$(sct_prompt_for_variable_or_default "message" "default-user")
sct_prompt_for_variable_or_default() {
    local prompt_message="$1"
    local default_value="$2"
    local user_input

    read -p "$prompt_message[$default_value]:" user_input
    user_input=${user_input:-$default_value}
    echo "$user_input"
}

# Get the parent folder name of the current script
# Only the folder name, not the full path
# Usage: THIS_SCRIPT_PARENT_FOLDER=$(get_script_parent_folder)
sct_get_script_parent_folder() {
    basename "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Create a folder if it does not exist and set its permissions and ownership
# Usage: create_folder_and_set_permisions "/path/to/folder" "permissions" "user:group"
sct_create_folder_and_set_permisions() {
    local dir="$1"
    local perm="$2"
    local userandgroup="$3"

    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
    
    chown -R "$userandgroup" "$dir" || { echo "ERROR: Failed to set ownership for $dir"; return 1; }
    chmod -R "$perm" "$dir" || { echo "ERROR: Failed to set permissions for $dir"; return 1; }
    
    echo "Folder '$dir' created (if not existing) and permissions set to '$perm' for '$userandgroup'."
}

# Start Docker containers using docker compose
# Additional environment variables can be passed as arguments
# Usage: sct_start_docker_compose_with_env_vars VAR1=value1 VAR2=value2 ...
sct_start_docker_compose_with_env_vars() {
    
    # Export the provided environment variables
    echo -e "\nStarting Docker containers with env "
    for env_var in "$@"; do
        var_name="${env_var%%=*}"
        var_value="${env_var#*=}"
        echo " $var_name=$var_value"
        export "$var_name"="$var_value"
    done

    # Start Docker containers
    if ! docker compose up -d --quiet-pull > /dev/null; then
        echo "Error: Failed to start Docker containers."
        docker compose logs
        return 1
    fi

    echo -e "\n\nDocker containers launched. Status:"
    docker compose ps

    # Unset the exported variables after use for security
    for env_var in "$@"; do
        var_name="${env_var%%=*}"
        unset "$var_name"
    done
}
