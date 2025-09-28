# Dotfiles

These are my macOS + lima (Fedora) dotfiles.
Lima is too inefficient for daily use, so I just use macOS for now.

## Usage

To set up Fedora in lima:
1. Install lima: `brew install lima`
2. Create the lima instance: `limactl start -y --name dev https://raw.githubusercontent.com/erazemk/dotfiles/main/lima.yaml`
3. (Optional) Check the provisioning progress: `tail -f ~/.lima/dev/serialv.log`
4. Add the lima instance to your ssh config (or just ssh using `ssh localhost -p 60000`):
```
Host lima
    HostName localhost
    Port 60000
```

Almost the whole [lima.yaml](lima.yaml) config is generic, but you will probably want to edit the
`[user]` section of `~/.config/git/config` to your own name after booting into the system.
