# Check if the current script runs as root
check_execution_user_is_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script as root"
        exit 1
    fi
}

# Install Docker CE if not already installed
install_docker() {
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

# Setup 2GB swap file if no swap is present
setup_swap() {
    if ! swapon --show | grep -q '^'; then
        echo "No swap found. Creating 2GB swap file..."
        fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
        chmod 600 /swapfile
        mkswap /swapfile > /dev/null
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        echo "Swap created and enabled."
    fi
}