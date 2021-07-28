#!/bin/sh
# Script for setting up WSL2 based on Fedora

# Variables
USER=default
PACKAGES=../configs/packages-fedora-wsl
EMAIL=default
GPG_PRIVKEY=default

setup() {
    # Optimize DNF
    echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
    echo "fastestmirror=True" >> /etc/dnf/dnf.conf

    # Update packages
    dnf upgrade -y --refresh

    # Enable delta RPMs
    dnf install -y deltarpm
    echo "deltarpm=True" >> /etc/dnf/dnf.conf
    dnf upgrade -y --refresh

    # Reinstall shadow-utils
    dnf reinstall -y shadow-utils

    # Enable trustywolf/wslu COPR repo and install wslu
    dnf copr enable -y trustywolf/wslu
    dnf install -y wslu

    # Set root password
    dnf install -y passwd cracklib-dicts
    clear
    echo "Set root password:"
    passwd root
}

install_packages() {
    dnf install -y $(grep "^[^#]" $PACKAGES)
}

cleanup() {
    dnf autoremove -y
    dnf clean all -y
}

setup_user() {
    # Install fish shell
    dnf install -y fish

    clear
    echo "Specify custom user's username:"
    read USER
    echo "Specify GPG privkey file:"
    read GPG_PRIVKEY
    echo "Specify GPG privkey email:"
    read EMAIL

    useradd -s /usr/bin/fish -G wheel $USER
    clear
    echo "Set password for $USER:"
    passwd $USER
}

configure_dotfiles() {
    dnf install -y git git-lfs
    su $USER -c "
        mkdir -p /home/$USER/.config;
        git clone https://gitlab.com/erazemk/dotfiles.git /home/$USER/.config/dotfiles;
        git -C /home/$USER/.config/dotfiles remote set-url origin git@gitlab.com:erazemk/dotfiles.git
    "
}

run_stow() {
    # Set up dotfiles
    dnf install -y stow

    cd /home/$USER/.config/dotfiles
    su $USER -c "
    mkdir -p /home/$USER/.local/bin
    stow -t /home/$USER -S bin

    rm -r /home/$USER/.config/fish
    mkdir -p /home/$USER/.config/fish
    stow -t /home/$USER -S fish

    mkdir -p /home/$USER/.config/gdb
    stow -t /home/$USER -S gdb

    mkdir -p /home/$USER/.config/git
    stow -t /home/$USER -S git

    mkdir -p /home/$USER/.config/gnupg
    stow -t /home/$USER -S gnupg

    mkdir -p /home/$USER/.config/mpv
    stow -t /home/$USER -S mpv

    mkdir -p /home/$USER/.config/nvim
    stow -t /home/$USER -S neovim

    mkdir -p /home/$USER/.ssh
    stow -t /home/$USER -S ssh

    mkdir -p /home/$USER/.config/youtube-dl
    stow -t /home/$USER -S youtube-dl
    "
}

configure_sudo() {
    clear

    # Allow the user to manually edit the sudoers file
    echo "Edit the sudoers file (press enter to continue)"
    read
    visudo
}

configure_gpg() {
    dnf install -y pinentry
    su $USER -c "mkdir /home/$USER/.config/gnupg; gpg --import $GPG_PRIVKEY"

    clear
    # Set GPG privkey trust
    echo "Set the GPG key's trust (press enter to continue)"
    read
    su $USER -c "gpg --edit-key $EMAIL"
}

setup_gotop() {
    curl -s https://api.github.com/repos/xxxserxxx/gotop/releases/latest \
            | grep "browser_download_url.*linux_amd64" \
            | cut -d : -f2,3 \
            | tr -d \" \
            | wget -qi -

    su $USER -c "mkdir -p /home/$USER/.local/bin"
    tar xvf $(find . -type f -name "gotop_*_linux_amd64.tgz") -C /home/$USER/.local/bin/
    chown -R $USER:$USER /home/$USER/.local/bin
    rm gotop_*_linux_amd64.tgz
}

setup_docker() {
    # Install docker repo
    dnf config-manager -y --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
}

# Run functions
setup
install_packages
configure_sudo
setup_user
configure_dotfiles
run_stow
setup_gotop
cleanup
