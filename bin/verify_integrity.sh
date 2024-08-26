#!/bin/bash

# Check if the vault directory and encrypted file exist
if [ ! -d "./vault" ] || [ ! -f "vault.tar.gz.gpg" ]; then
    echo "Error: vault directory or encrypted file not found."
    exit 1
fi

# Generate current checksum of the vault directory
CURRENT_CHECKSUM=$(find ./vault -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)
echo "Current vault checksum: $CURRENT_CHECKSUM"

# Prompt for passphrase
echo -n "Enter the passphrase for decryption: "
read -s PASSPHRASE
echo

# Decrypt and extract just the checksum from the encrypted file
STORED_CHECKSUM=$(echo "$PASSPHRASE" | gpg --batch --passphrase-fd 0 --decrypt vault.tar.gz.gpg 2>/dev/null | head -c 64)
echo "Stored checksum: $STORED_CHECKSUM"

# Compare checksums
if [ "$CURRENT_CHECKSUM" = "$STORED_CHECKSUM" ]; then
    echo "Integrity check passed: The vault directory matches the encrypted state."
    exit 0
else
    echo "Integrity check failed: The vault directory has been modified since the last encryption."
    exit 1
fi

