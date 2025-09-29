# ezy-install

**ezy-install** is a collection of scripts that simplifies the installation and configuration of common packages on Linux servers. Inspired by the "Add Roles and Features" wizard in Microsoft Windows Server, ezy-install offers a similar experience for Linux system administrators. It’s built for sysadmins and devs who want to deploy technical solutions quickly and consistently, without digging through outdated blogs or trial-and-error setup guides.

Setting up a Linux server for specific roles (such as DHCP, DNS, IT asset management, etc.) usually requires many manual steps. ezy-install automates these tasks, allowing you to prepare your server with just one command, and you’re up and running.


## Features

- Minimalist and easy to install  
- Downloads and runs install scripts on demand  
- Supports multiple tools: view  
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
ezy-install -l
or
ezy-install --list

# Install a service (example: MariaDB)
ezy-install mysql

# Show help
ezy-install -h
or
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



| Source Script / Guide                                                                                                                                             | Credit(s)     |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| [Beszel installation script](https://beszel.dev/guide/agent-installation#binary)                                                                                  | Beszel Team   |
| [GLPI guide on Tecmint](https://www.tecmint.com/install-glpi-asset-management-rhel/)                                                                              | James Kiarie  |
| MySQL installation guides                                                                                                                                         | Various       |
| [Nextcloud guide on idroot](https://idroot.us/install-nextcloud-centos-stream-10/)                                                                                | r00t          |
| PostgreSQL installation guides                                                                                                                                    | Various       |
| [Zabbix installation script](https://www.zabbix.com/download?zabbix=7.4&os_distribution=rocky_linux&os_version=9&components=server_frontend_agent&db=pgsql&ws=nginx) | Zabbix Team   |
| [Rudder installation script](https://docs.rudder.io/reference/8.3/installation/server/rhel.html)                                                                  | Rudder Team   |



## Use ezy-install to deploy a cost effective IT infrastructure (COEFIT)

🟢 = deployable using ezy-install

🔴 = not yet available

🟡 = planned

📀 = only in ISO Format

| Service Category                | Recommendation             | Rocky Linux 9 | Rocky Linux 10 |
|---------------------------------|----------------------------|---------------|----------------|
| Virtualization                  | Proxmox VE                 | 📀ISO        | 📀ISO          |
| Backup                          | Proxmox Backup Server      | 📀ISO        | 📀ISO          |
| Firewall / VPN / IDS / IPS      | Opnsense                   | 📀ISO        | 📀ISO          |
| Telephony                       | Issabel                    | 📀ISO        | 📀ISO          |
| Directory                       | Windows Active Directory   | 📀ISO        | 📀ISO          |
| Server OS                       | Rocky Linux                | 📀ISO        | 📀ISO          |
| Proxmox LCX Container Templates | Rocky Linux                | 🟢           | 🔴             |
| Collaboration & Communication   | Nextcloud Files            | 🟢           | 🟢             |
| Service Desk / Inventory        | GLPI                       | 🟡           | 🟡             |
| Monitoring                      | Zabbix                     | 🟡           | 🟡             |
| Patch Management                | Rudder                     | 🟡           | 🟡             |
| Database Server                 | MariaDB                    | 🟡           | 🟡             |
| Database Server                 | PostgreSQL                 | 🟡           | 🟡             |
| Password Management             | Passbolt                   | 🟡           | 🔴             |
| Log Management                  | Graylog                    | 🟡           | 🟡             |
| Asset Discovery                 | NetBox                     | 🟡           | 🟡             |
| SIEM                            | Wazuh                      | 🟡           | 🟡             |
| Office Productivity             | Libre Office               | 🔴           | 🔴             |


