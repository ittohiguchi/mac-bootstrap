#!/bin/sh

set -eu

if [ ! -f Brewfile ]; then
  printf 'Brewfile is missing\n' >&2
  exit 1
fi

assert_cask() {
  expected=$1
  if ! grep -Fqx "cask \"$expected\"" Brewfile; then
    printf 'missing cask: %s\n' "$expected" >&2
    exit 1
  fi
}

assert_formula() {
  expected=$1
  if ! grep -Fqx "brew \"$expected\"" Brewfile; then
    printf 'missing formula: %s\n' "$expected" >&2
    exit 1
  fi
}

if [ "$(grep -c '^cask ' Brewfile)" -ne 8 ]; then
  printf 'Brewfile must contain exactly eight casks\n' >&2
  exit 1
fi
if [ "$(grep -c '^brew ' Brewfile)" -ne 1 ]; then
  printf 'Brewfile must contain exactly one formula\n' >&2
  exit 1
fi

assert_cask google-chrome
assert_cask slack
assert_cask chatgpt
assert_cask tailscale-app
assert_cask docker-desktop
assert_cask iterm2
assert_cask 1password
assert_cask 1password-cli
assert_formula gh

printf 'brewfile_test: ok\n'
