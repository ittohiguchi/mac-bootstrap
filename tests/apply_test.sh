#!/bin/sh

set -eu

test_root=$(mktemp -d "${TMPDIR:-/tmp}/mac-bootstrap-test.XXXXXX")
calls_file="$test_root/calls"

cleanup() {
  case "$test_root" in
    "${TMPDIR:-/tmp}"/mac-bootstrap-test.*) ;;
    *) return 1 ;;
  esac

  if [ -d "$test_root" ] && [ ! -L "$test_root" ]; then
    rm -rf -- "$test_root"
  fi
}
trap cleanup EXIT

mock_bin="$test_root/mock-bin"
mkdir "$mock_bin"

for command_name in bash curl defaults hidutil killall mkdir osascript sh; do
  ln -s "$PWD/tests/mock_command.sh" "$mock_bin/$command_name"
done

/bin/mkdir -p "$test_root/home"
printf 'existing zsh configuration\n' > "$test_root/home/.zshrc"

CALLS_FILE="$calls_file" \
BASH_BIN="$mock_bin/bash" \
BREW_BIN="$test_root/missing-brew" \
HOMEBREW_BREW_CANDIDATES="$test_root/missing-brew" \
CURL_BIN="$mock_bin/curl" \
DEFAULTS_BIN="$mock_bin/defaults" \
HIDUTIL_BIN="$mock_bin/hidutil" \
KILLALL_BIN="$mock_bin/killall" \
MKDIR_BIN="$mock_bin/mkdir" \
OSASCRIPT_BIN="$mock_bin/osascript" \
SH_BIN="$mock_bin/sh" \
HOME="$test_root/home" \
  ./apply.sh

assert_call() {
  expected=$1
  if ! grep -Fqx "$expected" "$calls_file"; then
    printf 'missing call: %s\n' "$expected" >&2
    exit 1
  fi
}

assert_call "curl <-fsSL> <https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh>"
assert_call "sh <-c> <> <> <--unattended> <--keep-zshrc>"
assert_call "defaults <write> <com.apple.dock> <autohide> <-bool> <true>"
assert_call "defaults <write> <com.apple.dock> <tilesize> <-int> <69>"
assert_call "defaults <write> <com.apple.dock> <mru-spaces> <-bool> <false>"
assert_call "defaults <write> <com.apple.finder> <FXPreferredViewStyle> <-string> <Nlsv>"
assert_call "mkdir <-p> <$test_root/home/Pictures>"
assert_call "defaults <write> <com.apple.screencapture> <location> <-string> <$test_root/home/Pictures>"
assert_call "defaults <write> <com.apple.AppleMultitouchTrackpad> <Clicking> <-bool> <true>"
assert_call "defaults <write> <com.apple.AppleMultitouchTrackpad> <TrackpadRightClick> <-bool> <true>"
assert_call "defaults <write> <com.apple.AppleMultitouchTrackpad> <TrackpadCornerSecondaryClick> <-int> <0>"
assert_call "defaults <write> <com.apple.AppleMultitouchTrackpad> <FirstClickThreshold> <-int> <0>"
assert_call "defaults <write> <com.apple.AppleMultitouchTrackpad> <SecondClickThreshold> <-int> <0>"
assert_call "defaults <-currentHost> <write> <NSGlobalDomain> <com.apple.mouse.tapBehavior> <-int> <1>"
assert_call "defaults <write> <NSGlobalDomain> <com.apple.mouse.tapBehavior> <-int> <1>"
assert_call "defaults <write> <NSGlobalDomain> <KeyRepeat> <-int> <2>"
assert_call "defaults <write> <NSGlobalDomain> <InitialKeyRepeat> <-int> <15>"
assert_call "defaults <write> <com.apple.HIToolbox> <AppleGlobalTextInputProperties> <-dict-add> <TextInputGlobalPropertyPerContextInput> <-bool> <true>"
assert_call "defaults <write> <NSGlobalDomain> <NSAutomaticPeriodSubstitutionEnabled> <-bool> <false>"
if ! grep -Fq '/System/Library/PrivateFrameworks/CoreJapaneseEngine.framework' "$calls_file" ||
  ! grep -Fq 'NSClassFromString("JIMPreferences")' "$calls_file" ||
  ! grep -Fq 'sharedPreferences.setBoolForKey(' "$calls_file" ||
  ! grep -Fq 'JIMPrefFullWidthNumeralCharactersKey' "$calls_file"; then
  printf 'missing immediate Japanese input preference update\n' >&2
  exit 1
fi
if ! grep -Fq 'osascript <-l> <JavaScript> <-e>' "$calls_file" ||
  ! grep -Fq 'NXSetKeyRepeatInterval(handle, 2 / 60)' "$calls_file" ||
  ! grep -Fq 'NXSetKeyRepeatThreshold(handle, 15 / 60)' "$calls_file"; then
  printf 'missing immediate key repeat update\n' >&2
  exit 1
fi
assert_call "hidutil <list> <--ndjson> <--matching> <keyboard>"
assert_call "defaults <-currentHost> <write> <NSGlobalDomain> <com.apple.keyboard.modifiermapping.0-0-0> <-array> <{ HIDKeyboardModifierMappingSrc = 30064771129; HIDKeyboardModifierMappingDst = 30064771296; }>"
assert_call "defaults <-currentHost> <write> <NSGlobalDomain> <com.apple.keyboard.modifiermapping.1278-33-0> <-array> <{ HIDKeyboardModifierMappingSrc = 30064771129; HIDKeyboardModifierMappingDst = 30064771296; }>"
assert_call 'hidutil <property> <--set> <{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}>'
assert_call "killall <Dock>"
assert_call "killall <Finder>"
assert_call "killall <SystemUIServer>"

if grep -Eq '^(brew|bash) ' "$calls_file"; then
  printf 'apply.sh must not manage Homebrew\n' >&2
  exit 1
fi

if [ "$(cat "$test_root/home/.zshrc")" != "existing zsh configuration" ]; then
  printf 'existing .zshrc was changed\n' >&2
  exit 1
fi

/bin/mkdir "$test_root/home/.oh-my-zsh"
: > "$calls_file"

CALLS_FILE="$calls_file" \
BASH_BIN="$mock_bin/bash" \
BREW_BIN="$test_root/missing-brew" \
HOMEBREW_BREW_CANDIDATES="$test_root/missing-brew" \
CURL_BIN="$mock_bin/curl" \
DEFAULTS_BIN="$mock_bin/defaults" \
HIDUTIL_BIN="$mock_bin/hidutil" \
KILLALL_BIN="$mock_bin/killall" \
MKDIR_BIN="$mock_bin/mkdir" \
OSASCRIPT_BIN="$mock_bin/osascript" \
SH_BIN="$mock_bin/sh" \
HOME="$test_root/home" \
  ./apply.sh

if grep -Eq '^(curl|sh) ' "$calls_file"; then
  printf 'Oh My Zsh installer ran for an existing installation\n' >&2
  exit 1
fi

printf 'apply_test: ok\n'
