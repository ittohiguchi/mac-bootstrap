#!/bin/sh

set -eu

: "${HOME:?HOME must be set}"

CURL_BIN=${CURL_BIN:-/usr/bin/curl}
DEFAULTS_BIN=${DEFAULTS_BIN:-/usr/bin/defaults}
HIDUTIL_BIN=${HIDUTIL_BIN:-/usr/bin/hidutil}
KILLALL_BIN=${KILLALL_BIN:-/usr/bin/killall}
MKDIR_BIN=${MKDIR_BIN:-/bin/mkdir}
OSASCRIPT_BIN=${OSASCRIPT_BIN:-/usr/bin/osascript}
PLUTIL_BIN=${PLUTIL_BIN:-/usr/bin/plutil}
SH_BIN=${SH_BIN:-/bin/sh}

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

restart_if_running() {
  "$KILLALL_BIN" "$1" 2>/dev/null || true
}

set_fast_key_repeat() {
  # Persist the fastest values exposed by System Settings.
  "$DEFAULTS_BIN" write NSGlobalDomain KeyRepeat -int 2
  "$DEFAULTS_BIN" write NSGlobalDomain InitialKeyRepeat -int 15

  # System Settings also updates the HID event system. Do the same so the
  # change takes effect immediately instead of waiting for a new login.
  "$OSASCRIPT_BIN" -l JavaScript -e '
ObjC.import("IOKit");
const handle = $.NXOpenEventStatus();
if (Number(handle) === 0) {
  throw new Error("NXOpenEventStatus failed");
}
try {
  $.NXSetKeyRepeatInterval(handle, 2 / 60);
  $.NXSetKeyRepeatThreshold(handle, 15 / 60);
} finally {
  $.NXCloseEventStatus(handle);
}
'
}

set_caps_lock_to_control() {
  keyboard_services=$("$HIDUTIL_BIN" list --ndjson --matching keyboard)

  printf '%s\n' "$keyboard_services" | while IFS= read -r keyboard; do
    [ -n "$keyboard" ] || continue

    service_type=$(printf '%s' "$keyboard" | "$PLUTIL_BIN" -extract type raw -)
    [ "$service_type" = service ] || continue

    vendor_id=$(printf '%s' "$keyboard" | "$PLUTIL_BIN" -extract VendorID raw -)
    product_id=$(printf '%s' "$keyboard" | "$PLUTIL_BIN" -extract ProductID raw -)
    mapping_key="com.apple.keyboard.modifiermapping.$vendor_id-$product_id-0"

    # Persist the same per-keyboard ByHost preference used by System Settings.
    "$DEFAULTS_BIN" -currentHost write NSGlobalDomain "$mapping_key" -array \
      '{ HIDKeyboardModifierMappingSrc = 30064771129; HIDKeyboardModifierMappingDst = 30064771296; }'
  done

  # Apply the persisted mapping to the current HID session immediately.
  "$HIDUTIL_BIN" property --set \
    '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'
}

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

"$DEFAULTS_BIN" write com.apple.HIToolbox AppleGlobalTextInputProperties \
  -dict-add TextInputGlobalPropertyPerContextInput -bool true
"$DEFAULTS_BIN" write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Implementation: defaultsでは起動中のIMEが更新されないため、設定画面と同じsetterを使う。
"$OSASCRIPT_BIN" -l JavaScript -e '
ObjC.import("Foundation");
const framework = $.NSBundle.bundleWithPath(
  "/System/Library/PrivateFrameworks/CoreJapaneseEngine.framework"
);
if (!framework.load) {
  throw new Error("CoreJapaneseEngine failed to load");
}
const preferencesClass = $.NSClassFromString("JIMPreferences");
if (!preferencesClass) {
  throw new Error("JIMPreferences is unavailable");
}
preferencesClass.sharedPreferences.setBoolForKey(
  false,
  "JIMPrefFullWidthNumeralCharactersKey"
);
'

set_fast_key_repeat
set_caps_lock_to_control

restart_if_running Dock
restart_if_running Finder
restart_if_running SystemUIServer
