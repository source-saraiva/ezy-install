# ezy-install

**ezy-install** is a lightweight command-line launcher that fetches and runs installation scripts directly from this repository.  
It simplifies the setup of common solutions with one command.  
It also alleviates the trial-and-error process typically required when installing software, making the experience more like Windows-style roles and features installation.

## Features

- Minimalist and easy to install  
- Downloads and runs install scripts on demand  
- Supports multiple tools: DHCP, DNS, MySQL, GLPI, and more  
- Extensible: add your own `.sh` scripts to the repo  
- Supported Systems: [Rocky Linux 10](https://rockylinux.org/download) (or compatible RHEL-based systems)
  

## Installation

To install `ezy-install` globally on your system and start using it:

Download and install the launcher

```bash
sudo curl -fsSL https://raw.githubusercontent.com/source-saraiva/ezy-install/main/ezy-install.sh -o /usr/local/bin/ezy-install
sudo chmod +x /usr/local/bin/ezy-install
```
## Usage

💡 Tip: After installing, type `ez` and press `TAB` to autocomplete the `ezy-install` command in your terminal.

```bash

# View available scripts
ezy-install --list

# Install a service (example: MariaDB)
ezy-install mysql

# Show help
ezy-install --help
```

## Optional but Useful Tools
- Recommended Tools for troubleshooting and system monitoring:

```bash
sudo dnf install -y epel-release
sudo dnf update -y
sudo dnf install -y curl wget unzip openssl htop bind-utils net-tools traceroute tcpdump tar
```
