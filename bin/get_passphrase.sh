#!/bin/bash

# Check if the passphrase is stored in an environment variable
if [ -n "$WARD_PASSPHRASE" ]; then
    echo "$WARD_PASSPHRASE"
    exit 0
fi

# If not, and we're in an interactive environment, prompt the user
if [ -t 0 ]; then
    echo -n "Enter the passphrase for encryption: " >&2
    read -s passphrase
    echo >&2
    echo "$passphrase"
else
    echo "Error: WARD_PASSPHRASE environment variable not set in non-interactive mode." >&2
    exit 1
fi

