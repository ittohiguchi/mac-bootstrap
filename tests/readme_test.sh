#!/bin/sh

set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
readme="$repo_dir/README.md"

assert_contains() {
  expected=$1

  if ! grep -Fq -- "$expected" "$readme"; then
    printf 'README.md is missing: %s\n' "$expected" >&2
    exit 1
  fi
}

assert_contains "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
assert_contains 'brew bundle --file ./Brewfile'
assert_contains "eval \"\$(/opt/homebrew/bin/brew shellenv)\""
assert_contains "eval \"\$(/usr/local/bin/brew shellenv)\""
assert_contains './apply.sh'

printf 'readme_test: ok\n'
