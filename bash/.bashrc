# ~/.bashrc — personal customizations only; system defaults sourced below

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return ;;
esac

# Source system-wide defaults (Debian/Ubuntu skeleton)
if [ -f /etc/skel/.bashrc ]; then
  source /etc/skel/.bashrc
fi

# Load custom aliases, functions, and settings
source ~/.config/bash/rc

# Shell integrations
eval "$(zoxide init bash --cmd cd)"
eval "$(starship init bash)"

export PATH="$HOME/.devcontainers/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin:$PATH"
