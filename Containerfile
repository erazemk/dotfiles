FROM quay.io/fedora/fedora

ENV TERM=xterm-256color

# Copy configuration files
COPY aws/config /etc/aws/config
COPY devcontainers/dnf.conf /etc/dnf/dnf.conf
COPY devcontainers/defaults.sh /etc/profile.d/defaults.sh
COPY fish/conf.d/defaults.fish /etc/fish/conf.d/defaults.fish
COPY git/config /etc/gitconfig

# Install development-related packages
RUN dnf --assumeyes --refresh upgrade \
    && dnf --assumeyes install \
    awscli2 \
    coreutils \
    curl \
    diffutils \
    fish \
    gh \
    git \
    git-lfs \
    golang \
    helix \
    jq \
    make \
    nodejs \
    ripgrep \
    sudo \
    which \
    && dnf clean all --assumeyes

# Configure fish shell
RUN rm -rf /etc/skel/* /root/.*rc /root/.bash*
RUN chsh -s /usr/bin/fish root

# AWS CLI configuration
ENV AWS_CONFIG_FILE=/etc/aws/config

# Add a user 'dev'
RUN useradd -m -s /usr/bin/fish -G wheel dev \
    && passwd -d dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev
