#!/bin/sh

command_name=$(basename "$0")

printf '%s' "$command_name" >> "$CALLS_FILE"
for argument in "$@"; do
  printf ' <%s>' "$argument" >> "$CALLS_FILE"
done
printf '\n' >> "$CALLS_FILE"

if [ "$command_name" = bash ] && [ -n "${MOCK_INSTALL_BREW_PATH:-}" ]; then
  /bin/mkdir -p "$(dirname "$MOCK_INSTALL_BREW_PATH")"
  /bin/ln -s "$MOCK_COMMAND_SOURCE" "$MOCK_INSTALL_BREW_PATH"
fi
