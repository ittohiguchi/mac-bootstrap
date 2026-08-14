#!/bin/sh

set -eu

test_root=$(mktemp -d "${TMPDIR:-/tmp}/mac-bootstrap-homebrew-test.XXXXXX")
calls_file="$test_root/calls"

cleanup() {
  case "$test_root" in
    "${TMPDIR:-/tmp}"/mac-bootstrap-homebrew-test.*) ;;
    *) return 1 ;;
  esac

  if [ -d "$test_root" ] && [ ! -L "$test_root" ]; then
    rm -rf -- "$test_root"
  fi
}
trap cleanup EXIT

mock_bin="$test_root/mock-bin"
/bin/mkdir -p "$mock_bin" "$test_root/home/.oh-my-zsh"

for command_name in bash curl defaults killall mkdir sh; do
  ln -s "$PWD/tests/mock_command.sh" "$mock_bin/$command_name"
done

printf 'existing profile configuration\n' > "$test_root/home/.zprofile"

run_apply() {
  CALLS_FILE="$calls_file" \
  BASH_BIN="$mock_bin/bash" \
  BREW_BIN="$mock_bin/brew" \
  CURL_BIN="$mock_bin/curl" \
  DEFAULTS_BIN="$mock_bin/defaults" \
  HOMEBREW_BREW_CANDIDATES="$mock_bin/brew" \
  KILLALL_BIN="$mock_bin/killall" \
  MKDIR_BIN="$mock_bin/mkdir" \
  MOCK_COMMAND_SOURCE="$PWD/tests/mock_command.sh" \
  MOCK_INSTALL_BREW_PATH="$mock_bin/brew" \
  SH_BIN="$mock_bin/sh" \
  HOME="$test_root/home" \
    ./apply.sh
}

run_apply

assert_call() {
  expected=$1
  if ! grep -Fqx "$expected" "$calls_file"; then
    printf 'missing call: %s\n' "$expected" >&2
    exit 1
  fi
}

assert_call "curl <-fsSL> <https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh>"
assert_call "bash <-c> <>"
assert_call "brew <shellenv>"
assert_call "brew <bundle> <--file=$PWD/Brewfile>"

shellenv_line="eval \"\$($mock_bin/brew shellenv)\""
if ! grep -Fqx 'existing profile configuration' "$test_root/home/.zprofile"; then
  printf 'existing .zprofile content was changed\n' >&2
  exit 1
fi
if [ "$(grep -Fxc "$shellenv_line" "$test_root/home/.zprofile")" -ne 1 ]; then
  printf 'brew shellenv was not persisted exactly once\n' >&2
  exit 1
fi

: > "$calls_file"
run_apply

if grep -Eq '^(bash|curl) ' "$calls_file"; then
  printf 'Homebrew installer ran for an existing installation\n' >&2
  exit 1
fi
if [ "$(grep -Fxc "$shellenv_line" "$test_root/home/.zprofile")" -ne 1 ]; then
  printf 'brew shellenv was duplicated\n' >&2
  exit 1
fi

printf 'homebrew_install_test: ok\n'
