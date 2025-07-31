# ezy-install

**ezy-install** is a lightweight command-line launcher that fetches and runs installation scripts directly from this repository. It simplifies the setup of common solutions with one command.  
It also alleviates the trial-and-error process typically required when installing software, making the experience more like Windows-style roles and features installation.

## Features

- Minimalist and easy to install  
- Downloads and runs install scripts on demand  
- Supports multiple tools: DHCP, DNS, MySQL, GLPI, and more  
- Extensible: add your own `.sh` scripts to the repo  
- Supported Systems: [Rocky Linux 10](https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10.0-x86_64-minimal.iso) (or compatible RHEL-based systems)
  

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
## Credits
> The following scripts and guides were used to identify required packages and installation logic. Many of them were written for other distributions — such as Ubuntu and Rocky Linux 8 — and were significantly adapted to work reliably on Rocky Linux 10 within the `ezy-install` framework.



| Source Script / Guide                                                                                  | Author(s)       |
|--------------------------------------------------------------------------------------------------------|-----------------|
| [Beszel installation script](https://beszel.dev/guide/agent-installation#binary)                       | Beszel Team     |
| [GLPI guide on Tecmint](https://www.tecmint.com/install-glpi-asset-management-rhel/)                   | James Kiarie    |
| MySQL installation guides                                                                              | Various         |
| [Nextcloud guide on idroot](https://idroot.us/install-nextcloud-centos-stream-10/)                     | r00t            |
| PostgreSQL installation guides                                                                         | Various         |
| [Technitium installation script](https://blog.technitium.com/2017/11/running-dns-server-on-ubuntu-linux.html)| Technitum Team|
| [Zabbix installation script](https://www.zabbix.com/download?zabbix=7.4&os_distribution=rocky_linux&os_version=9&components=server_frontend_agent&db=pgsql&ws=nginx) | Zabbix Team|


