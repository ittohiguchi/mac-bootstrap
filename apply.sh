#!/bin/sh

set -eu

: "${HOME:?HOME must be set}"

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

BREW_BIN=${BREW_BIN:-}
CURL_BIN=${CURL_BIN:-/usr/bin/curl}
DEFAULTS_BIN=${DEFAULTS_BIN:-/usr/bin/defaults}
KILLALL_BIN=${KILLALL_BIN:-/usr/bin/killall}
MKDIR_BIN=${MKDIR_BIN:-/bin/mkdir}
SH_BIN=${SH_BIN:-/bin/sh}

if [ -z "$BREW_BIN" ]; then
  BREW_BIN=$(command -v brew || true)
fi

if [ -z "$BREW_BIN" ]; then
  printf 'Homebrew is required before running apply.sh.\n' >&2
  exit 1
fi

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    return
  fi

  installer=$(
    "$CURL_BIN" -fsSL \
      https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
  )
  "$SH_BIN" -c "$installer" "" --unattended --keep-zshrc
}

set_symbolic_hotkey() {
  hotkey_id=$1
  enabled=$2
  parameters=$3

  "$DEFAULTS_BIN" write com.apple.symbolichotkeys AppleSymbolicHotKeys \
    -dict-add "$hotkey_id" \
    "{ enabled = $enabled; value = { parameters = $parameters; type = standard; }; }"
}

restart_if_running() {
  "$KILLALL_BIN" "$1" 2>/dev/null || true
}

"$BREW_BIN" bundle --file="$SCRIPT_DIR/Brewfile"
install_oh_my_zsh

"$DEFAULTS_BIN" write com.apple.dock autohide -bool true
"$DEFAULTS_BIN" write com.apple.dock tilesize -int 69
"$DEFAULTS_BIN" write com.apple.dock mru-spaces -bool false

"$DEFAULTS_BIN" write com.apple.finder FXPreferredViewStyle -string Nlsv

"$MKDIR_BIN" -p "$HOME/Pictures"
"$DEFAULTS_BIN" write com.apple.screencapture location -string "$HOME/Pictures"

"$DEFAULTS_BIN" write com.apple.AppleMultitouchTrackpad Clicking -bool true
"$DEFAULTS_BIN" write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
"$DEFAULTS_BIN" write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 0
"$DEFAULTS_BIN" write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
"$DEFAULTS_BIN" write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0
"$DEFAULTS_BIN" -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
"$DEFAULTS_BIN" write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

set_symbolic_hotkey 60 0 '(32, 49, 262144)'
set_symbolic_hotkey 61 1 '(32, 49, 1048576)'
set_symbolic_hotkey 64 1 '(32, 49, 524288)'

restart_if_running Dock
restart_if_running Finder
restart_if_running SystemUIServer
