#!/bin/sh

printf '%s' "$(basename "$0")" >> "$CALLS_FILE"
for argument in "$@"; do
  printf ' <%s>' "$argument" >> "$CALLS_FILE"
done
printf '\n' >> "$CALLS_FILE"
