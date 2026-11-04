#!/usr/bin/env bash

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

#
# Set up homebrew
#

if [[ ! -x /opt/homebrew/bin/brew ]]; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv bash)"

echo "Installing packages..."
brew install -q --formulae colima docker docker-buildx docker-compose docker-credential-helper fish gh go jq stow uv
brew install -q --casks pearcleaner rectangle scroll-reverser visual-studio-code

# Set personal/DevRev hostname and install DevRev-specific packages
[[ "$(scutil --get ComputerName)" == "Erazem's MacBook" ]] || sudo scutil --set ComputerName "Erazem's MacBook"
if systemextensionsctl list | grep -q jumpcloud; then
    echo "Setting DevRev hostname..."
    [[ "$(scutil --get LocalHostName)" == "wMBP" ]] || sudo scutil --set LocalHostName "wMBP"
    [[ "$(scutil --get HostName 2>/dev/null)" == "wMBP" ]] || sudo scutil --set HostName "wMBP"
else
    echo "Setting personal hostname..."
    [[ "$(scutil --get LocalHostName)" == "eMBP" ]] || sudo scutil --set LocalHostName "eMBP"
    [[ "$(scutil --get HostName 2>/dev/null)" == "eMBP" ]] || sudo scutil --set HostName "eMBP"
fi

#
# Set up dotfiles
#

echo "Setting up dotfiles..."

mkdir -p "$HOME/.docker"
cat > "$HOME/.docker/config.json" <<'EOF'
{
  "credsStore": "osxkeychain",
  "cliPluginsExtraDirs": [
    "/opt/homebrew/lib/docker/cli-plugins"
  ]
}
EOF

mkdir -p "$HOME/.config/fish"
stow -t "$HOME" -R fish

mkdir -p "$HOME/.config/git"
stow -t "$HOME" -R git

mkdir -p "$HOME/Library/LaunchAgents"
stow -t "$HOME" -R launchctl

mkdir -p "$HOME/Library/Application Support/Code/User"
stow -t "$HOME" -R vscode

#
# Set up the GitHub SSH key
#

mkdir -p "$HOME/.ssh"
stow -t "$HOME" -R ssh
chmod 700 "$HOME/.ssh"

# Set up the GitHub SSH key
if [[ ! -f "$HOME/.ssh/github" ]]; then
    echo "Creating GitHub SSH key..."
    ssh-keygen -t ed25519 -f "$HOME/.ssh/github" -N ""
fi
if ! gh auth status >/dev/null 2>&1; then
    echo "Logging into GitHub..."
    gh auth login --git-protocol ssh --scopes admin:public_key --skip-ssh-key
fi

key_title="$(scutil --get LocalHostName)"
local_key="$(awk '{print $1 " " $2}' "$HOME/.ssh/github.pub")"
github_keys="$(gh api --paginate --slurp 'user/keys?per_page=100')"

machine_key="$(jq -c --arg title "$key_title" '[.[][] | select(.title == $title)][0] // null' <<< "$github_keys")"
registered_key="$(jq -r '(.key // "") | split(" ") | .[0:2] | join(" ")' <<< "$machine_key")"

if [[ "$registered_key" != "$local_key" ]]; then
    key_id="$(jq -r '.id // empty' <<< "$machine_key")"
    if [[ -n "$key_id" ]]; then
        echo "Removing outdated GitHub SSH key for $key_title..."
        gh api --method DELETE "user/keys/$key_id"
    fi

    echo "Adding new GitHub SSH key for $key_title..."
    gh ssh-key add "$HOME/.ssh/github.pub" --title "$key_title"
    open "https://github.com/settings/keys"
    read -r -p "Authorize the SSH key for SSO if needed, then press Enter to continue..."
fi

# 
# Set up Amp
#

mkdir -p "$HOME/Code"

if [[ ! -x "$HOME/.amp/bin/amp" ]]; then
    echo "Installing Amp..."
    curl -fsSL https://ampcode.com/install.sh | bash
fi
if [[ "$("$HOME/.amp/bin/amp" account list)" == "No saved accounts." ]]; then
    echo "Logging into Amp..."
    "$HOME/.amp/bin/amp" login
fi
if ! launchctl print "gui/$(id -u)/com.ampcode.runner" >/dev/null 2>&1; then
    echo "Starting Amp runner service..."
    launchctl enable "gui/$(id -u)/com.ampcode.runner"
    launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.ampcode.runner.plist"
fi

#
# Set up Colima
#

instances="$(colima list --json)"
if ! jq -e -s 'any(.[]; .name == "default")' <<< "$instances" >/dev/null; then
    echo "Creating default Colima instance..."
    colima start --profile default --cpu 12 --memory 24 --disk 256 --ssh-agent
fi
if ! launchctl print "gui/$(id -u)/sh.brew.colima" >/dev/null 2>&1; then
    echo "Starting Colima service..."
    brew services start colima
fi

#
# Switch default shell to fish
#

fish_path="$(command -v fish)"
if ! grep -Fqx "$fish_path" /etc/shells; then
    echo "Adding fish to /etc/shells..."
    printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
fi

login_shell="$(dscl . -read "/Users/$(id -un)" UserShell)"
login_shell="${login_shell#UserShell: }"
if [[ "$login_shell" != "$fish_path" ]]; then
    echo "Changing default shell to fish..."
    sudo chsh -s "$fish_path" "$(id -un)"
fi

#
# Set up macOS preferences
#

echo "Setting macOS preferences"

# Dock
echo "Setting Dock preferences..."
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock orientation -string right
defaults write com.apple.dock mineffect -string scale
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false # Keep Space order stable
defaults write com.apple.dock persistent-others -array # Remove pinned folders
if systemextensionsctl list | grep -q jumpcloud; then
    # Pin only Google Chrome to the Dock
    defaults write com.apple.dock persistent-apps -array '
    { "tile-data" = { "file-data" = {
        "_CFURLString" = "file:///Applications/Google%20Chrome.app/";
        "_CFURLStringType" = 15;
    }; }; }'
fi

# Finder
echo "Setting Finder preferences..."
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder NewWindowTarget -string PfHm # Open new windows in Home directory
defaults write com.apple.finder _FXSortFoldersFirst -bool true # Sort folders first
defaults write com.apple.finder ShowRecentTags -bool false
defaults write com.apple.finder FXPreferredGroupBy -string None # Don't group files
defaults write com.apple.finder FXArrangeGroupViewBy -string Name # Sort by name

# Pearcleaner
echo "Setting Pearcleaner preferences..."
defaults write com.alienator88.Pearcleaner settings.general.brew -bool true # Enable Homebrew cleanup
defaults write com.alienator88.Pearcleaner settings.general.confirmAlert -bool true # Show confirmation alerts

# Rectangle
echo "Setting Rectangle preferences..."
defaults write com.knollsoft.Rectangle allowAnyShortcut -bool true
defaults write com.knollsoft.Rectangle alternateDefaultShortcuts -bool true
defaults write com.knollsoft.Rectangle hideMenubarIcon -bool true
defaults write com.knollsoft.Rectangle gapSize -float 8.0
defaults write com.knollsoft.Rectangle unsnapRestore -int 1

# System updates
echo "Setting system update preferences..."
if [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null)" != "1" ]]; then
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
fi
if [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload 2>/dev/null)" != "1" ]]; then
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
fi
if [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates 2>/dev/null)" != "1" ]]; then
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
fi
if [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall 2>/dev/null)" != "1" ]]; then
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
fi
if [[ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall 2>/dev/null)" != "1" ]]; then
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
fi

# Terminal
echo "Setting Terminal preferences..."
osascript \
    -e 'tell application "Terminal"' \
    -e 'set font size of settings set "Basic" to 16' \
    -e 'set default settings to settings set "Basic"' \
    -e 'set startup settings to settings set "Basic"' \
    -e 'end tell'

# Touchpad
echo "Setting touchpad preferences..."
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2

# Window manager
echo "Setting window manager preferences..."
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
defaults write com.apple.WindowManager StandardHideDesktopIcons -bool true
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool true

echo "Restarting system services"
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall WindowManager 2>/dev/null || true
