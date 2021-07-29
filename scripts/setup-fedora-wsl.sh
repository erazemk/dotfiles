#!/bin/sh
# Script for setting up WSL2 based on Fedora

# Variables
USER=""
EMAIL=""
GPG_PRIVKEY=""
ROOT_PASS=""
USER_PASS=""

setup() {
    # Ask all user questions
    echo -n "Enter root user's password: "
    read ROOT_PASS
    echo -n "Enter custom user's username: "
    read USER
    echo -n "Enter custom user's password: "
    read USER_PASS
    echo -n "Enter GPG private key file name: "
    read GPG_PRIVKEY
    echo -n "Enter GPG private key email: "
    read EMAIL

    # Optimize DNF
    echo "Optimizing DNF"
    echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
    echo "fastestmirror=True" >> /etc/dnf/dnf.conf
    
    # Enable installing man pages
    sed -i '/tsflags=nodocs/d' /etc/dnf/dnf.conf

    # Update packages
    echo "Upgrading packages"
    dnf upgrade -y --quiet --refresh >/dev/null

    # Enable delta RPMs
    echo "Enabling delta RPMs"
    dnf install -y --quiet deltarpm >/dev/null
    echo "deltarpm=True" >> /etc/dnf/dnf.conf
    dnf upgrade -y --quiet --refresh >/dev/null

    # Reinstall shadow-utils
    echo "Reinstalling shadow utils"
    dnf reinstall -y --quiet shadow-utils >/dev/null

    # Enable trustywolf/wslu COPR repo and install wslu
    echo "Enabling trustywolf/wslu COPR repo"
    dnf install -y --quiet dnf-plugins-core dnf-utils >/dev/null
    dnf copr enable -y trustywolf/wslu &>/dev/null
    dnf install -y --quiet wslu >/dev/null

    # Set root password
    dnf install -y --quiet passwd cracklib-dicts ncurses >/dev/null
    echo -e "$ROOT_PASS\n$ROOT_PASS" | passwd root >/dev/null
}

configure_sudo() {
    # Allow the user to manually edit the sudoers file
    echo "Edit the sudoers file (press enter to continue)"
    read
    visudo
}

install_packages() {
    echo "Installing packages"
    dnf install -y --quiet findutils >/dev/null
    packages=$(find /root -type f -name "packages-fedora-wsl")
    echo "Packages to install: $(echo $(grep "^[^#]" $packages))"
    dnf install -y --quiet $(grep "^[^#]" $packages) >/dev/null
}

setup_user() {
    # Install fish shell
    dnf install -y --quiet fish >/dev/null
    useradd -s /usr/bin/fish -G wheel $USER
    echo -e "$USER_PASS\n$USER_PASS" | passwd $USER >/dev/null
}

configure_dotfiles() {
    echo "Cloning dotfiles repo"
    dnf install -y --quiet git git-lfs >/dev/null
    su $USER -c "
        mkdir -p /home/$USER/.config;
        git clone --quiet https://gitlab.com/erazemk/dotfiles.git /home/$USER/.config/dotfiles;
        git -C /home/$USER/.config/dotfiles remote set-url origin git@gitlab.com:erazemk/dotfiles.git
    "
}

run_stow() {
    # Set up dotfiles
    echo "Setting up dotfiles"
    dnf install -y --quiet stow >/dev/null

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
    chmod 700 /home/$USER/.config/gnupg
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

configure_gpg() {
    echo "Setting up GPG key"
    dnf install -y --quiet pinentry >/dev/null

    GPG_PRIVKEY=$(basename $GPG_PRIVKEY)
    gpg_privkey_file=$(find / -type f -name $GPG_PRIVKEY -print -quit)
    
    chown $USER:$USER $gpg_privkey_file
    mv $gpg_privkey_file /home/$USER/

    su $USER -c "mkdir /home/$USER/.config/gnupg; gpg --import /home/$USER/$GPG_PRIVKEY"

    # Set GPG privkey trust
    echo "Set the GPG key's trust (press enter to continue)"
    read
    su $USER -c "gpg --edit-key $EMAIL"
}

setup_gotop() {
    echo "Installing gotop"
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

cleanup() {
    echo "Cleaning up"
    dnf autoremove -y --quiet >/dev/null
    dnf clean all -y --quiet >/dev/null

    rm /home/$USER/.bash*
}

# Run functions
setup
configure_sudo
install_packages
setup_user
configure_dotfiles
run_stow
configure_gpg
setup_gotop
cleanup
