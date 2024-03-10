#!/bin/bash

# -e: exit on error
# -u: exit on unset variables
set -eu

if ! chezmoi="$(command -v chezmoi)"; then
	bin_dir="${HOME}/.local/bin"
	chezmoi="${bin_dir}/chezmoi"
	echo "Installing chezmoi to '${chezmoi}'" >&2
	if command -v curl >/dev/null; then
		chezmoi_install_script="$(curl -fsSL get.chezmoi.io)"
	elif command -v wget >/dev/null; then
		chezmoi_install_script="$(wget -qO- get.chezmoi.io)"
	else
		echo "To install chezmoi, you must have curl or wget installed." >&2
		exit 1
	fi
	sh -c "${chezmoi_install_script}" -- -b "${bin_dir}"
	unset chezmoi_install_script bin_dir
fi

# Check if zsh is available and install it if it's not
if ! command -v zsh >/dev/null 2>&1; then
    echo "Zsh is not installed. Installing Zsh..."
    sudo apt-get update && sudo apt-get install -y zsh
else
    echo "Zsh is already installed."
fi

# Check if Oh My Zsh is installed and install it if it's not
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    echo "Oh My Zsh is not installed. Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
else
    echo "Oh My Zsh is already installed."
fi

# Set zsh as the default shell if it's not already the default
current_shell=$(basename "$SHELL")
if [ "$current_shell" != "zsh" ]; then
    echo "Setting zsh as the default shell..."
    chsh -s "$(command -v zsh)"
else
    echo "Zsh is already the default shell."
fi

# List of plugins to install
plugins=("zsh-autosuggestions" "zsh-syntax-highlighting")

# Directory for custom plugins
plugin_dir="${HOME}/.oh-my-zsh/custom/plugins/"
theme_dir="${HOME}/.oh-my-zsh/custom/themes/"

# Ensure the plugin directory exists
mkdir -p "${plugin_dir}"

# Loop over the plugins and clone them
for plugin in "${plugins[@]}"; do
	if [ ! -d "${plugin_dir}/${plugin}" ]; then
		echo "Installing ${plugin}..."
		git clone "https://github.com/zsh-users/${plugin}.git" "${plugin_dir}/${plugin}"
	else
		echo "${plugin} already installed"
	fi
done

# Check if fzf is installed and install it if it's not
if ! command -v fzf >/dev/null 2>&1; then
	echo "fzf is not installed. Installing fzf..."
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install --all
else
	echo "fzf is already installed."
fi

# Source zsh-interactive-cd.plugin.zsh in .zshrc
zshrc="${HOME}/.zshrc"
interactive_cd_plugin="${HOME}/.oh-my-zsh/custom/plugins/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh"

if ! grep -q "zsh-interactive-cd.plugin.zsh" "$zshrc"; then
	echo "Sourcing zsh-interactive-cd.plugin.zsh in .zshrc..."
	echo "source $interactive_cd_plugin" >> "$zshrc"
else
	echo "zsh-interactive-cd.plugin.zsh is already sourced in .zshrc."
fi


# Check if powerlevel10k is installed and install it if it's not
if [ ! -d "${theme_dir}/powerlevel10k" ]; then
	echo "Installing powerlevel10k..."
	git clone "https://github.com/romkatv/powerlevel10k.git" "${theme_dir}/powerlevel10k"
else
  	echo "Powerlevel10k already installed"
fi

# Check if Starship is installed, and install it if it is not
if ! command -v starship >/dev/null; then
    echo "Starship is not installed. Installing Starship..."
    if command -v curl >/dev/null; then
        sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
    elif command -v wget >/dev/null; then
        sh -c "$(wget -qO- https://starship.rs/install.sh)" -- -y
    else
        echo "To install Starship, you must have curl or wget installed." >&2
        exit 1
    fi
else
    echo "Starship is already installed."
fi



# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

set -- init --apply --source="${script_dir}"

echo "Running 'chezmoi $*'" >&2
# exec: replace current process with chezmoi
exec "$chezmoi" "$@"
