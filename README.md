# Dotfiles

Personal dotfiles for a minimal, keyboard-driven Linux desktop. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Usage

Clone to your home directory:

```sh
git clone https://github.com/Tomeriko96/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Install [GNU Stow](https://www.gnu.org/software/stow/) and stow what you need:

```sh
stow i3
stow alacritty
# ...etc
```

Unstow with:

```sh
stow -D i3
```

## Included

- i3, Alacritty, Polybar, Picom, Pyradio, Rofi, Starship, Waybar, backgrounds

## Notes

Edit configs here, then restow. All configs are modular and reproducible.

## Hotfixes

- Disable laptop trackpad

```
sudo modprobe -r psmouse
```
