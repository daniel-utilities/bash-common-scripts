#!/bin/bash
source common-functions.sh
source wsl-functions.sh

OUTPUT="$(cmd_exec "pause")"

echo "$OUTPUT"
echo $?
