# ezy-install


**ezy-install** is a lightweight command-line launcher that fetches and runs installation scripts directly from this repository.
It simplifies the setup of common solutions with one command.
It also alleviates the trial-and-error process typically required when installing software, making the experience more like Windows-style roles and features installation.


## Features

- Minimalist and easy to install
- Downloads and runs install scripts on demand
- Supports multiple tools: dhcp, MariaDB, glpi, and more
- Extensible: add your own `.sh` scripts to the repo

## Installation

To install `ezy-install` globally on your system:

```bash
sudo curl -fsSL https://raw.githubusercontent.com/source-saraiva/ezy-install/main/ezy-install.sh -o /usr/local/bin/ezy-install && sudo chmod +x /usr/local/bin/ezy-install
