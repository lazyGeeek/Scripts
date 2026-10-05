#!/usr/bin/env zsh

set -e
set -u
set -o pipefail

# -----------------------------
# Configuration
# -----------------------------

TMP_DIR="/tmp"

GO_VERSION="1.27.1"
GO_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
GO_ARCHIVE="${TMP_DIR}/go${GO_VERSION}.linux-amd64.tar.gz"
GO_INSTALL_DIR="/usr/local/go"

NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
NVIM_ARCHIVE="${TMP_DIR}/nvim-linux-x86_64.tar.gz"
NVIM_INSTALL_DIR="/opt/nvim"

FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.zip"
FONT_ARCHIVE="${TMP_DIR}/JetBrainsMono.zip"
FONT_DIR="${HOME}/.local/share/fonts"

GO_BIN_DIR="${HOME}/.go/bin"
GO_MODCACHE="${HOME}/.go/pkg/mod"
GOPATH_DIR="${HOME}/.go"
ZSHRC="${HOME}/.zshrc"

# -----------------------------
# Error handling
# -----------------------------

error_handler() {
    local exit_code=$?
    echo "Error: command failed on line ${LINENO}: ${1}" >&2
    exit "${exit_code}"
}

trap 'error_handler "$BASH_COMMAND"' ERR

# -----------------------------
# Helper functions
# -----------------------------

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: required command not found: $1" >&2
        exit 1
    fi
}

download_file() {
    local url="$1"
    local output="$2"

    echo "Downloading: ${url}"
    curl --fail --location --retry 3 --output "${output}" "${url}"
}

add_to_path() {
    local path_entry="$1"
    local path_line="export PATH=\"\$PATH:${path_entry}\""

    if ! grep -Fqx "${path_line}" "${ZSHRC}" 2>/dev/null; then
        printf '%s\n' "${path_line}" >> "${ZSHRC}"
    fi
}

# -----------------------------
# Install functions
# -----------------------------

install_go() {
    echo
    echo "Installing Go ${GO_VERSION}..."

    download_file "${GO_URL}" "${GO_ARCHIVE}"

    sudo rm -rf "${GO_INSTALL_DIR}"
    sudo tar -C /usr/local -xzf "${GO_ARCHIVE}"

    mkdir -p "${GO_BIN_DIR}" "${GO_MODCACHE}" "${GOPATH_DIR}"

    "${GO_INSTALL_DIR}/bin/go" env -w "GOBIN=${GO_BIN_DIR}"
    "${GO_INSTALL_DIR}/bin/go" env -w "GOMODCACHE=${GO_MODCACHE}"
    "${GO_INSTALL_DIR}/bin/go" env -w "GOPATH=${GOPATH_DIR}"

    add_to_path "${GO_INSTALL_DIR}/bin"
    add_to_path "${GO_BIN_DIR}"

    echo "Go installed successfully."
}

install_nvim() {
    echo
    echo "Installing Neovim..."

    download_file "${NVIM_URL}" "${NVIM_ARCHIVE}"

    sudo rm -rf "${TMP_DIR}/nvim-linux-x86_64" "${NVIM_INSTALL_DIR}"
    sudo tar -C "${TMP_DIR}" -xzf "${NVIM_ARCHIVE}"
    sudo mv "${TMP_DIR}/nvim-linux-x86_64" "${NVIM_INSTALL_DIR}"

    add_to_path "${NVIM_INSTALL_DIR}/bin"

    echo "Neovim installed successfully."
}

install_font() {
    echo
    echo "Installing JetBrainsMono Nerd Font..."

    require_command unzip
    require_command fc-cache

    download_file "${FONT_URL}" "${FONT_ARCHIVE}"

    mkdir -p "${FONT_DIR}"
    unzip -o -q "${FONT_ARCHIVE}" -d "${FONT_DIR}"
    fc-cache -f "${FONT_DIR}"

    echo "JetBrainsMono Nerd Font installed successfully."
}

install_all() {
    install_go
    install_nvim
    install_font
}

# -----------------------------
# Dependency checks
# -----------------------------

require_command curl
require_command sudo
require_command tar
require_command grep

# -----------------------------
# Menu
# -----------------------------

while true; do
    echo
    echo "Select an installation option:"
    echo "  1) Install Go"
    echo "  2) Install Neovim"
    echo "  3) Install JetBrainsMono Nerd Font"
    echo "  4) Install all"
    echo "  5) Exit"
    echo

    read -r "choice?Enter your choice [1-5]: "

    case "${choice}" in
        1)
            install_go
            ;;
        2)
            install_nvim
            ;;
        3)
            install_font
            ;;
        4)
            install_all
            ;;
        5)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose a number from 1 to 5."
            ;;
    esac

    echo
    read -r "continue_choice?Press Enter to return to the menu, or type q to quit: "
    [[ "${continue_choice:l}" == "q" ]] && exit 0
done

