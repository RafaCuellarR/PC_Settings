#!/usr/bin/env bash
#
# install_pkgs.sh - Basic Ubuntu configuration
#
# Usage:
#   ./scripts/install_pkgs.sh            Install Sublime Text, ROS 2 Jazzy, ESP-IDF and Pico SDK
#                                        (ESP-IDF and Pico SDK go in $HOME)
#   ./scripts/install_pkgs.sh aliases    Copy .bash_aliases to $HOME

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

ESP_IDF_DIR="$HOME/esp-idf"
PICO_SDK_DIR="$HOME/pico-sdk"

install_aliases() {
    local src="$REPO_DIR/.bash_aliases"
    local dst="$HOME/.bash_aliases"

    if [[ ! -f "$src" ]]; then
        echo "Error: $src not found." >&2
        exit 1
    fi

    cp "$src" "$dst"
    echo "Copied .bash_aliases to $HOME"
    echo "Run 'source ~/.bash_aliases' or open a new terminal to apply it."
}

install_esp_idf() {
    echo "==> Installing ESP-IDF prerequisites"
    sudo apt-get update
    sudo apt-get install -y \
        git wget flex bison gperf python3 python3-pip python3-venv \
        cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0

    if [[ -d "$ESP_IDF_DIR" ]]; then
        echo "ESP-IDF already present at $ESP_IDF_DIR, skipping clone."
    else
        echo "==> Cloning ESP-IDF into $ESP_IDF_DIR"
        git clone --recursive https://github.com/espressif/esp-idf.git "$ESP_IDF_DIR"
    fi

    echo "==> Running ESP-IDF install script"
    (cd "$ESP_IDF_DIR" && ./install.sh all)

    echo "ESP-IDF installed. To use it in a shell run: . $ESP_IDF_DIR/export.sh"
}

install_pico_sdk() {
    echo "==> Installing Pico SDK prerequisites"
    sudo apt-get update
    sudo apt-get install -y \
        git cmake gcc-arm-none-eabi libnewlib-arm-none-eabi \
        libstdc++-arm-none-eabi-newlib build-essential python3

    if [[ -d "$PICO_SDK_DIR" ]]; then
        echo "Pico SDK already present at $PICO_SDK_DIR, skipping clone."
    else
        echo "==> Cloning Pico SDK into $PICO_SDK_DIR"
        git clone https://github.com/raspberrypi/pico-sdk.git "$PICO_SDK_DIR"
    fi

    echo "==> Initializing Pico SDK submodules"
    (cd "$PICO_SDK_DIR" && git submodule update --init)

    echo "Pico SDK installed. To use it: export PICO_SDK_PATH=$PICO_SDK_DIR"
}

install_ros2_jazzy() {
    local codename
    codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"

    if [[ "$codename" != "noble" ]]; then
        echo "Warning: ROS 2 Jazzy targets Ubuntu 24.04 (noble); detected '$codename'. Skipping ROS 2." >&2
        return 0
    fi

    if [[ -f /opt/ros/jazzy/setup.bash ]]; then
        echo "ROS 2 Jazzy already installed, skipping install."
    else
        echo "==> Setting up ROS 2 apt repository"
        sudo apt-get update
        sudo apt-get install -y locales software-properties-common curl
        sudo locale-gen en_US en_US.UTF-8
        sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
        sudo add-apt-repository -y universe

        local version deb
        version="$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
            | grep -F "tag_name" | awk -F\" '{print $4}')"
        deb="/tmp/ros2-apt-source.deb"
        curl -L -o "$deb" \
            "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${version}/ros2-apt-source_${version}.${codename}_all.deb"
        sudo dpkg -i "$deb"
        rm -f "$deb"

        echo "==> Installing ROS 2 Jazzy (desktop) and dev tools"
        sudo apt-get update
        sudo apt-get upgrade -y
        sudo apt-get install -y ros-jazzy-desktop ros-dev-tools
    fi

    local line="source /opt/ros/jazzy/setup.bash"
    if grep -qxF "$line" "$HOME/.bashrc" 2>/dev/null; then
        echo "'$line' already in ~/.bashrc"
    else
        echo "$line" >> "$HOME/.bashrc"
        echo "Added '$line' to ~/.bashrc"
    fi
}

install_sublime() {
    if command -v subl >/dev/null 2>&1; then
        echo "Sublime Text already installed, skipping."
        return 0
    fi

    echo "==> Installing Sublime Text"
    sudo apt-get update
    sudo apt-get install -y wget gpg apt-transport-https ca-certificates

    sudo mkdir -p /etc/apt/keyrings
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
        | gpg --dearmor \
        | sudo tee /etc/apt/keyrings/sublimehq-pub.gpg > /dev/null

    printf 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.gpg\n' \
        | sudo tee /etc/apt/sources.list.d/sublime-text.sources > /dev/null

    sudo apt-get update
    sudo apt-get install -y sublime-text
}

case "${1:-}" in
    aliases)
        install_aliases
        ;;
    "")
        install_sublime
        install_ros2_jazzy
        install_esp_idf
        install_pico_sdk
        ;;
    *)
        echo "Unknown argument: $1" >&2
        echo "Usage: $0 [aliases]" >&2
        exit 1
        ;;
esac