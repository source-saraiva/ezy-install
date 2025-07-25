# ezy-install


**ezy-install** is a lightweight command-line launcher that fetches and runs installation scripts directly from this repository. It simplifies the setup of common development tools and environments with one command.

## Features

- Minimalist and easy to install
- Downloads and runs install scripts on demand
- Supports multiple tools: MySQL, MariaDB, Docker, and more
- Extensible: add your own `.sh` scripts to the repo

## Installation

To install `ezy-install` globally on your system:

```bash
curl -fsSL https://raw.githubusercontent.com/source-saraiva/ezy-install/main/ezy-install | sudo tee /usr/local/bin/ezy-install > /dev/null
sudo chmod +x /usr/local/bin/ezy-install
