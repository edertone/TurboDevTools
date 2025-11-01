#!/bin/bash

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

# Start Docker containers using docker compose
# Additional environment variables can be passed as arguments
# Usage: start_docker_compose_with_env_vars VAR1=value1 VAR2=value2 ...
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
