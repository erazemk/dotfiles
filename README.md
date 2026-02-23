# ~/.config/dotfiles

My (fairly lean) dotfiles.
Primarily used on macOS, but also usable in Linux environments.

Run `setup.sh` to bootstrap a dev container or your local machine.

## Dev container

[`devcontainer.json`](devcontainer.json) contains a template dev container config, copy that to your repo's `.devcontainer/devcontainer.json` and adjust as needed. It's based on the [`Containerfile`](Containerfile), which is a Fedora development setup with some extra DevRev-specific tools.
