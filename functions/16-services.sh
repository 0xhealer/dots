#!/usr/bin/env bash
# functions/16-services.sh -- module name: "services"
# Enables Docker and Tailscale, cross-referenced from winget.txt's
# Docker.DockerDesktop and Tailscale.Tailscale -- also matches this
# box's original stated purpose (Docker media server, Tailscale remote
# access, see areas notes). Installing the packages alone (pacman.txt)
# doesn't start anything -- this is the step that actually turns them on.
set -euo pipefail

unit_exists() { systemctl list-unit-files "$1" 2> /dev/null | grep -q "^$1"; }

write_module_header "Enabling Docker"
if ! unit_exists docker.service; then
    echo -e "\033[33m[SKIP] docker.service not installed on this machine\033[0m"
else
    sudo systemctl enable --now docker.service
    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        sudo usermod -aG docker "$USER"
        echo -e "\033[33m[INFO] Added ${USER} to the docker group -- log out and back in for this to take effect (docker commands need sudo until then)\033[0m"
fi
echo -e "\033[32m[SUCCESS] Docker enabled\033[0m"
fi

write_module_header "Enabling Tailscale"
if unit_exists tailscaled.service; then
    sudo systemctl enable --now tailscaled.service
    echo -e "\033[32m[SUCCESS] tailscaled enabled\033[0m"
    echo "!! Run 'sudo tailscale up' to actually join your tailnet -- this step only starts the daemon, it doesn't authenticate (that needs an interactive browser login this installer can't do unattended)"
else
    echo -e "\033[33m[SKIP] tailscaled.service not installed (run './install.sh third-party-apps' or install Tailscale first)\033[0m"
fi
