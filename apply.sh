#!/bin/sh

set -eu

: "${HOME:?HOME must be set}"

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

BASH_BIN=${BASH_BIN:-/bin/bash}
BREW_BIN_WAS_SET=${BREW_BIN+x}
BREW_BIN=${BREW_BIN:-}
CURL_BIN=${CURL_BIN:-/usr/bin/curl}
DEFAULTS_BIN=${DEFAULTS_BIN:-/usr/bin/defaults}
HOMEBREW_BREW_CANDIDATES=${HOMEBREW_BREW_CANDIDATES:-/opt/homebrew/bin/brew /usr/local/bin/brew}
KILLALL_BIN=${KILLALL_BIN:-/usr/bin/killall}
MKDIR_BIN=${MKDIR_BIN:-/bin/mkdir}
SH_BIN=${SH_BIN:-/bin/sh}

find_brew() {
  if [ -n "$BREW_BIN" ] && [ -x "$BREW_BIN" ]; then
    return
  fi

  if [ "$BREW_BIN_WAS_SET" != x ]; then
    BREW_BIN=$(command -v brew || true)
    if [ -n "$BREW_BIN" ] && [ -x "$BREW_BIN" ]; then
      return
    fi
  fi

  for candidate in $HOMEBREW_BREW_CANDIDATES; do
    if [ -x "$candidate" ]; then
      BREW_BIN=$candidate
      return
    fi
  done

  BREW_BIN=
  return 1
}

install_homebrew() {
  if find_brew; then
    return
  fi

  installer=$(
    "$CURL_BIN" -fsSL \
      https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
  )
  "$BASH_BIN" -c "$installer"

  if ! find_brew; then
    printf 'Homebrew installation completed, but brew was not found.\n' >&2
    exit 1
  fi
}

configure_brew_shellenv() {
  profile="$HOME/.zprofile"
  shellenv_line="eval \"\$($BREW_BIN shellenv)\""

  if [ ! -f "$profile" ] || ! grep -Fqx "$shellenv_line" "$profile"; then
    if [ -s "$profile" ]; then
      printf '\n' >> "$profile"
    fi
    printf '%s\n' "$shellenv_line" >> "$profile"
  fi

  eval "$("$BREW_BIN" shellenv)"
}

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

install_homebrew
configure_brew_shellenv
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
