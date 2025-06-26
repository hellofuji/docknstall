#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Bold colors
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_MAGENTA='\033[1;35m'
BOLD_CYAN='\033[1;36m'

# Function to display error messages
error_msg() {
    echo -e "${BOLD_RED}[ERROR]${NC} ${RED}$1${NC}"
}

# Function to display success messages
success_msg() {
    echo -e "${BOLD_GREEN}[SUCCESS]${NC} ${GREEN}$1${NC}"
}

# Function to display info messages
info_msg() {
    echo -e "${BOLD_BLUE}[INFO]${NC} ${BLUE}$1${NC}"
}

# Function to display warning messages
warning_msg() {
    echo -e "${BOLD_YELLOW}[WARNING]${NC} ${YELLOW}$1${NC}"
}

# Function to display header
header() {
    echo -e "${BOLD_MAGENTA}\n$1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get list of normal users
get_users() {
    # Get users with UID >= 1000 (normal users) and shell access
    getent passwd | awk -F: '$3 >= 1000 && $7 != "/usr/sbin/nologin" && $7 != "/bin/false" {print $1}'
}

# Function to select user from available users
select_user() {
    local users=($(get_users))
    
    if [ ${#users[@]} -eq 0 ]; then
        error_msg "No normal users found on this system."
        return 1
    fi
    
    header "Available Users"
    for i in "${!users[@]}"; do
        echo -e "${BOLD_CYAN}$((i+1)). ${users[i]}${NC}"
    done
    
    while true; do
        read -rp "Select user to add to docker group (1-${#users[@]}): " user_choice
        
        if [[ "$user_choice" =~ ^[0-9]+$ ]] && [ "$user_choice" -ge 1 ] && [ "$user_choice" -le ${#users[@]} ]; then
            selected_user="${users[$((user_choice-1))]}"
            info_msg "Selected user: $selected_user"
            return 0
        else
            error_msg "Invalid selection. Please enter a number between 1 and ${#users[@]}."
        fi
    done
}

# Function to clean up on exit
cleanup() {
    if [ $? -ne 0 ]; then
        error_msg "Installation process encountered errors."
    fi
}

# Function to install Docker on Ubuntu
install_docker_ubuntu() {
    header "Setting up Docker on Ubuntu"
    
    info_msg "Updating package index..."
    sudo apt-get update || return 1
    
    info_msg "Installing prerequisite packages..."
    sudo apt-get install -y ca-certificates curl || return 1
    
    info_msg "Configuring Docker repository..."
    sudo install -m 0755 -d /etc/apt/keyrings || return 1
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || return 1
    sudo chmod a+r /etc/apt/keyrings/docker.asc || return 1
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || return 1
    
    sudo apt-get update || return 1
    
    info_msg "Installing Docker packages..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
    
    success_msg "Docker installed successfully"
    return 0
}

# Function to install Docker on Debian/Raspberry Pi OS
install_docker_debian() {
    header "Setting up Docker on Debian/Raspberry Pi OS"
    
    info_msg "Updating package index..."
    sudo apt-get update || return 1
    
    info_msg "Installing prerequisite packages..."
    sudo apt-get install -y ca-certificates curl || return 1
    
    info_msg "Configuring Docker repository..."
    sudo install -m 0755 -d /etc/apt/keyrings || return 1
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc || return 1
    sudo chmod a+r /etc/apt/keyrings/docker.asc || return 1
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || return 1
    
    sudo apt-get update || return 1
    
    info_msg "Installing Docker packages..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
    
    success_msg "Docker installed successfully"
    return 0
}

# Function to install Docker on Fedora
install_docker_fedora() {
    header "Setting up Docker on Fedora"
    
    info_msg "Configuring Docker repository..."
    sudo dnf -y install dnf-plugins-core || return 1
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo || return 1
    
    info_msg "Installing Docker packages..."
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
    
    info_msg "Starting Docker service..."
    sudo systemctl enable --now docker || return 1
    
    success_msg "Docker installed successfully"
    return 0
}

# Function to install Docker on CentOS
install_docker_centos() {
    header "Setting up Docker on CentOS"
    
    info_msg "Configuring Docker repository..."
    sudo dnf -y install dnf-plugins-core || return 1
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || return 1
    
    info_msg "Installing Docker packages..."
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
    
    info_msg "Starting Docker service..."
    sudo systemctl enable --now docker || return 1
    
    success_msg "Docker installed successfully"
    return 0
}

# Function to configure user permissions
configure_user_permissions() {
    local user=$1
    
    header "Configuring User Permissions"
    
    info_msg "Adding $user to docker group..."
    sudo usermod -aG docker "$user" || return 1
    
    success_msg "User $user added to docker group"
    warning_msg "Important: The user must log out and back in for these changes to take effect."
    return 0
}

# Function to verify Docker installation
verify_installation() {
    header "Verifying Docker Installation"
    
    info_msg "Running test container..."
    if sudo docker run --rm hello-world; then
        success_msg "Docker is functioning correctly"
        return 0
    else
        error_msg "Docker test failed"
        return 1
    fi
}

# Main script execution
main() {
    # Display welcome message
    header "Docker Installation Manager"
    echo -e "${CYAN}This script will install Docker and configure user permissions.${NC}"
    
    # Check if script is run as root
    if [ "$(id -u)" -eq 0 ]; then
        error_msg "This script should not be run as root. Please run as a normal user with sudo privileges."
        exit 1
    fi
    
    # Check if Docker is already installed
    if command_exists docker; then
        warning_msg "Docker appears to be already installed."
        read -rp "Would you like to reinstall Docker? (y/N) " reinstall_choice
        if [[ ! "$reinstall_choice" =~ ^[Yy]$ ]]; then
            info_msg "Skipping Docker installation."
            exit 0
        fi
    fi
    
    # Distribution selection menu
    header "Select Your Linux Distribution"
    echo -e "${BOLD_CYAN}1. Ubuntu${NC}"
    echo -e "${BOLD_CYAN}2. Debian/Raspberry Pi OS (64-bit)${NC}"
    echo -e "${BOLD_CYAN}3. Fedora${NC}"
    echo -e "${BOLD_CYAN}4. CentOS${NC}"
    echo -e "${BOLD_RED}5. Exit${NC}"
    
    while true; do
        read -rp "Enter your choice (1-5): " distro_choice
        
        case $distro_choice in
            1) install_docker_ubuntu; break ;;
            2) install_docker_debian; break ;;
            3) install_docker_fedora; break ;;
            4) install_docker_centos; break ;;
            5) info_msg "Installation canceled"; exit 0 ;;
            *) error_msg "Invalid selection" ;;
        esac
    done
    
    # Check if Docker installation succeeded
    if [ $? -ne 0 ]; then
        error_msg "Docker installation failed"
        exit 1
    fi
    
    # User selection and configuration
    if ! select_user; then
        exit 1
    fi
    
    if ! configure_user_permissions "$selected_user"; then
        exit 1
    fi
    
    # Verification
    if ! verify_installation; then
        exit 1
    fi
    
    # Final instructions
    header "Installation Complete"
    echo -e "${GREEN}Docker is now ready to use.${NC}"
    echo -e "${YELLOW}Heads-up: '$selected_user' has been added to the Docker group. To activate these changes, a logout and login (or system reboot) is required.${NC}"
}

# Trap EXIT signal to perform cleanup
trap cleanup EXIT

# Execute main function
main
