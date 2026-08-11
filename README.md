<h1 align="center">Dotfiles</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux">
  <img src="https://img.shields.io/badge/CachyOS-0088CC?style=for-the-badge&logo=arch-linux&logoColor=white" alt="CachyOS">
  <br>
  <img src="https://img.shields.io/github/last-commit/0xhealer/dotfiles?style=flat-square" alt="Last commit">
  <img src="https://img.shields.io/github/license/0xhealer/dotfiles?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/shell-PowerShell%20%7C%20Bash-89e051?style=flat-square" alt="Shell">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square" alt="PRs welcome">
</p>

## Overview

Personal, modular dotfiles for both machines I use day to day: a Windows box
and a CachyOS (Arch) Linux box running Hyprland/Niri with the Noctalia shell.
Configs, fonts, and package lists live in one shared tree; each platform gets
its own installer entrypoint, helper library, and numbered install steps, so
either machine can be bootstrapped from a clean install with a single command.

- **Windows** — `install.ps1` + `modules/` (numbered `*.ps1` steps) + `helpers/common.ps1`
- **Linux** — `install.sh` + `functions/` (numbered `*.sh` steps) + `helpers/common.sh`
- Shared: `configs/`, `fonts/`, `packages/`

## Bootstrap

One-liner remote bootstrap — downloads the repo and runs the installer for you.

### Windows
```powershell
iwr -useb https://raw.githubusercontent.com/0xhealer/dotfiles/main/bootstrap.ps1 | iex
```

### Linux
```shell
curl -fsSL "https://raw.githubusercontent.com/0xhealer/dotfiles/main/bootstrap.sh" | bash
```

## Layout

```
dotfiles/
├── install.ps1 / install.sh
├── bootstrap.ps1 / bootstrap.sh
├── helpers/
│   ├── common.ps1
│   └── common.sh
├── modules/
├── functions/
├── configs/
│   ├── git/ nvim/ starship/ fastfetch/ vscode/
│   ├── powershell/ windows-terminal/
│   └── hypr/ niri/ noctalia/ shell/ terminal/
├── packages/
│   ├── winget.txt / scoop.txt
│   ├── pacman.txt / aur.txt
│   └── dnf.txt / apt.txt
└── fonts/
```

## Usage

Run a subset of steps by name (works the same on both platforms):

```powershell
.\install.ps1 -Modules starship,git
```
```shell
./install.sh starship git
```
