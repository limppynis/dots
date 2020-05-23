#!/bin/bash

# Use rofi to enter some text or choose between options. If any text is chosen
# or selected, it will be echoed, otherwise the command will exit with 1.
# Usage:
#     ./rofi_input <prompt> <n_lines>
#     get_options | ./rofi_input <prompt> <n_lines>
input=$(
  rofi \
    -dmenu \
    -i -p "${1:-input}" \
    -location 2 -width 450 \
    -lines ${2:-0} \
    ${@:2} <&0
)

if [[ -z "$input" ]]; then
  exit 1
else
  echo $input
fi
