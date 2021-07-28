#!/usr/bin/env bash
# Automatically (un)install applications and do other setup tasks

user=$USER
dnf_install=(
    'evolution'
    'fish'
    'git-lfs'
    'gnome-tweaks'
    'htop'
    'neovim'
    'pulseeffects'
    'stow'
    'syncthing'
    'toolbox'
    'wireshark'
)
dnf_remove=(
    'gnome-photos'
    'gnome-tour'
    'gnome-video-effects'
    'libreoffice-core'
    'rhythmbox'
    'totem'
    'yelp'
)
flatpak_install=(
    'com.bitwarden.desktop'
    'com.discordapp.Discord'
    'com.github.tchx84.Flatseal'
    'com.spotify.Client'
    'im.riot.Riot'
    'io.github.celluloid_player.Celluloid'
    'org.ghidra_sre.Ghidra'
    'org.gnome.GHex'
    'org.jitsi.jitsi-meet'
    'org.mozilla.firefox'
    'org.qbittorrent.qBittorrent'
    'org.telegram.desktop'
    'us.zoom.Zoom'
)

#
# Function definitions
#
dnf_upgrade_packages() {
    sudo dnf upgrade -y --refresh
}

dnf_uninstall_packages() {
    sudo dnf autoremove -y ${dnf_remove[@]}
}

dnf_install_packages() {
    sudo dnf install -y ${dnf_install[@]}
}

flatpak_install_packages() {
    flatpak install flathub -y ${flatpak_install[@]}
}

dnf_change_settings() {
    echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf
    echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
}

change_shell() {
    sudo lchsh $user <<< "/usr/bin/fish"
}

enable_systemd_services() {
    systemctl enable --now --user syncthing.service
}

add_sudo_asterisks() {
    sudo sed -i '/^Defaults    env_reset/ s/$/,pwfeedback/' /etc/sudoers
}

tlp_install() {
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y https://repo.linrunner.de/fedora/tlp/repos/releases/tlp-release.fc$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y tlp tlp-rdw akmod-acpi_call
    sudo dnf --enablerepo=tlp-updates-testing install -y akmod-acpi_call
}

add_user_to_groups() {
    sudo usermod -aG wireshark docker $user
}

#
# Main
#

#dnf_change_settings
#dnf_upgrade_packages
#dnf_uninstall_packages
#dnf_install_packages
flatpak_install_packages
#change_shell
#enable_systemd_services
#add_sudo_asterisks

#TODO: tlp dotfiles rpmfusion flathub
