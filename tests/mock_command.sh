#!/bin/sh

printf '%s' "$(basename "$0")" >> "$CALLS_FILE"
for argument in "$@"; do
  printf ' <%s>' "$argument" >> "$CALLS_FILE"
done
printf '\n' >> "$CALLS_FILE"

if [ "$(basename "$0")" = hidutil ] && [ "${1:-}" = list ]; then
  printf '%s\n' \
    '{"type":"service","VendorID":0,"ProductID":0}' \
    '{"type":"service","VendorID":1278,"ProductID":33}' \
    '{"type":"device","VendorID":1278,"ProductID":33}'
fi
