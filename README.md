# docknstall

A robust shell script that automates Docker installation and configuration on major Linux distributions.

## Features

- Supports Ubuntu, Debian, Raspberry Pi OS (64-bit), Fedora, and CentOS
- Handles repository setup and package installation
- Properly configures user permissions
- Verifies installation with test container
- Color-coded output for easy debugging

## Requirements

- Linux system (one of the supported distributions)
- `sudo` privileges
- Internet connection

## Usage

```bash
# Clone the repository locally:
git clone https://github.com/hellofuji/docknstall

# Make the script executable:
chmod +x docknstall.sh

# Run the script:
./docknstall.sh
```

## Post-Installation
After installation completes:
```bash
# Log out and back in for group changes to take effect
logout

# Verify Docker works without sudo:
docker run hello-world
```
