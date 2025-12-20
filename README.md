sudo modprobe -r psmouse

# Dotfiles (Stow-Ready) for Debian Linux

This repository contains my configuration files (dotfiles) for a minimal, keyboard-driven Debian Linux desktop environment, organized for easy management with [GNU Stow](https://www.gnu.org/software/stow/).

---

## Features

- **Modular structure**: Each app/config has its own directory, mirroring the target home directory layout.
- **Easy symlinking**: Use GNU Stow to quickly deploy or update configs.
- **Keyboard-driven workflow**: i3, Alacritty, Rofi, Polybar, and more.
- **Custom scripts, shaders, and themes**: All organized for clarity and portability.

---

## Directory Structure

Each top-level directory is ready to be stowed. For example:

```
alacritty/.config/alacritty/
bash/.config/bash/
hypr/.config/hypr/
i3/.config/i3/
picom/.config/picom/
polybar/.config/polybar/
pyradio/.config/pyradio/
rofi/.config/rofi/
starship/.config/
waybar/.config/waybar/
backgrounds/.local/share/backgrounds/
```

---

## How to Use with GNU Stow

1. **Install Stow** (if not already):
	```sh
	sudo apt install stow
	```

2. **Clone this repo to your home directory** (recommended):
	```sh
	git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
	cd ~/.dotfiles
	```

3. **Stow a config** (creates symlinks in your home directory):
	```sh
	stow alacritty
	stow bash
	stow hypr
	stow i3
	stow polybar
	stow picom
	stow pyradio
	stow rofi
	stow starship
	stow waybar
	stow backgrounds
	```
	You can stow all at once, or just the ones you want.

4. **Unstow a config** (removes symlinks):
	```sh
	stow -D polybar
	```

---

## Notes

- If you want to update a config, edit it in this repo and re-stow.
- If you want to remove legacy configs, see the repo for a safe removal script/command.
- All configs are designed for a clean, reproducible setup.

---

## Troubleshooting

#### Fix: Left-click not working

```sh
sudo modprobe -r psmouse
```
