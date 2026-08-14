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

for command_name in defaults killall mkdir; do
  ln -s "$PWD/tests/mock_command.sh" "$mock_bin/$command_name"
done

CALLS_FILE="$calls_file" \
DEFAULTS_BIN="$mock_bin/defaults" \
KILLALL_BIN="$mock_bin/killall" \
MKDIR_BIN="$mock_bin/mkdir" \
HOME="$test_root/home" \
  ./apply.sh

assert_call() {
  expected=$1
  if ! grep -Fqx "$expected" "$calls_file"; then
    printf 'missing call: %s\n' "$expected" >&2
    exit 1
  fi
}

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
assert_call "defaults <write> <com.apple.symbolichotkeys> <AppleSymbolicHotKeys> <-dict-add> <60> <{ enabled = 0; value = { parameters = (32, 49, 262144); type = standard; }; }>"
assert_call "defaults <write> <com.apple.symbolichotkeys> <AppleSymbolicHotKeys> <-dict-add> <61> <{ enabled = 1; value = { parameters = (32, 49, 1048576); type = standard; }; }>"
assert_call "defaults <write> <com.apple.symbolichotkeys> <AppleSymbolicHotKeys> <-dict-add> <64> <{ enabled = 1; value = { parameters = (32, 49, 524288); type = standard; }; }>"
assert_call "killall <Dock>"
assert_call "killall <Finder>"
assert_call "killall <SystemUIServer>"

printf 'apply_test: ok\n'
