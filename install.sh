#!/bin/sh

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
  fi
done

git clone "https://github.com/romkatv/powerlevel10k.git" "${theme_dir}/powerlevel10k"

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

set -- init --apply --source="${script_dir}"

echo "Running 'chezmoi $*'" >&2
# exec: replace current process with chezmoi
exec "$chezmoi" "$@"
