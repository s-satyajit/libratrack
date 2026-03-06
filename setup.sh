#!/usr/bin/env bash
# setup.sh - One-step build setup for LibraTrack
# Usage: ./setup.sh

set -e

BOLD="\033[1m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}+======================================+${RESET}"
echo -e "${CYAN}${BOLD}|       LibraTrack - Setup             |${RESET}"
echo -e "${CYAN}${BOLD}+======================================+${RESET}"
echo ""

# -- Auto-install a missing package -----------------------------------------------
install_pkg() {
    local pkg="$1"
    if command -v apt-get &>/dev/null; then
        echo -e "${YELLOW}  Installing ${pkg} via apt...${RESET}"
        sudo apt-get install -y "$pkg"
    elif command -v brew &>/dev/null; then
        echo -e "${YELLOW}  Installing ${pkg} via brew...${RESET}"
        brew install "$pkg"
    elif command -v dnf &>/dev/null; then
        echo -e "${YELLOW}  Installing ${pkg} via dnf...${RESET}"
        sudo dnf install -y "$pkg"
    elif command -v pacman &>/dev/null; then
        echo -e "${YELLOW}  Installing ${pkg} via pacman...${RESET}"
        sudo pacman -S --noconfirm "$pkg"
    else
        echo -e "${RED}  [X] Cannot auto-install ${pkg}: no supported package manager found.${RESET}"
        echo -e "${YELLOW}      Install it manually and re-run setup.sh${RESET}"
        exit 1
    fi
}

# -- Dependency checks (auto-install if missing) ----------------------------------
for tool in cmake git; do
    if ! command -v "$tool" &>/dev/null; then
        echo -e "${YELLOW}  [!] Missing: ${tool} - attempting auto-install...${RESET}"
        install_pkg "$tool"
        if ! command -v "$tool" &>/dev/null; then
            echo -e "${RED}  [X] ${tool} still not found after install. Please install manually.${RESET}"
            exit 1
        fi
    fi
    echo -e "${GREEN}  [OK] Found: ${tool} ($(command -v "$tool"))${RESET}"
done

# -- Check for a C++17 capable compiler -------------------------------------------
CXX_CMD=""
for candidate in g++ c++ clang++; do
    if command -v "$candidate" &>/dev/null; then
        # Check version supports C++17
        ver=$("$candidate" --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1)
        major=$(echo "$ver" | cut -d. -f1)
        if [[ "$candidate" == "clang++" ]] && [[ "$major" -ge 5 ]]; then
            CXX_CMD="$candidate"; break
        elif [[ "$major" -ge 7 ]]; then
            CXX_CMD="$candidate"; break
        fi
    fi
done

if [[ -z "$CXX_CMD" ]]; then
    echo -e "${YELLOW}  [!] No C++17 compiler found - attempting auto-install...${RESET}"
    if command -v apt-get &>/dev/null; then
        install_pkg "g++"
    elif command -v brew &>/dev/null; then
        install_pkg "gcc"
    elif command -v dnf &>/dev/null; then
        install_pkg "gcc-c++"
    elif command -v pacman &>/dev/null; then
        install_pkg "gcc"
    fi
    CXX_CMD="g++"
fi
echo -e "${GREEN}  [OK] Found C++ compiler: ${CXX_CMD} ($(command -v "$CXX_CMD"))${RESET}"
echo ""

# -- CMake configure --------------------------------------------------------------
echo -e "${BOLD}[1/2] Configuring build...${RESET}"
if ! cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug 2>&1 | grep -v "^--"; then
    echo -e "${RED}  [X] CMake configure failed.${RESET}"
    exit 1
fi
echo ""

# -- Build ------------------------------------------------------------------------
echo -e "${BOLD}[2/2] Building...${RESET}"
if ! cmake --build build --parallel; then
    echo -e "${RED}  [X] Build failed.${RESET}"
    exit 1
fi

echo ""
echo -e "${GREEN}${BOLD}  [OK] Setup complete!${RESET}"
echo ""
echo -e "  Run the test for a specific issue:"
echo -e "    ${CYAN}./check.sh <issue-number>${RESET}"
echo -e "  Examples:"
echo -e "    ${CYAN}./check.sh 1${RESET}   - tests your fix for Issue #01"
echo -e "    ${CYAN}./check.sh 42${RESET}  - tests your fix for Issue #42"
echo ""
