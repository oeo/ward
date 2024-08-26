#!/bin/bash

# Function to securely remove files
secure_remove() {
    if command -v shred > /dev/null; then
        shred -u "$1"
    else
        rm -P "$1"
    fi
}

# Prompt for passphrase
#echo "Enter the passphrase for decryption:"
#read -s PASSPHRASE
echo -n "Enter the passphrase for decryption: "
read -s PASSPHRASE
echo >&2

# Create a temporary file to store the passphrase
PASSPHRASE_FILE=$(mktemp)
echo "$PASSPHRASE" > "$PASSPHRASE_FILE"

# Decrypt the encrypted tar archive
gpg --batch --passphrase-file "$PASSPHRASE_FILE" --decrypt vault.tar.gz.gpg > vault_with_checksum.tar.gz

# Check if decryption was successful
if [ $? -ne 0 ]; then
    echo "Failed to decrypt archive. Exiting."
    secure_remove "$PASSPHRASE_FILE"
    exit 1
fi

# Extract the checksum and the actual tar content
STORED_CHECKSUM=$(head -c 64 vault_with_checksum.tar.gz)
tail -c +65 vault_with_checksum.tar.gz > vault.tar.gz

# Extract the tar archive
tar -xzf vault.tar.gz

# Clean up
secure_remove "$PASSPHRASE_FILE"
secure_remove vault_with_checksum.tar.gz
secure_remove vault.tar.gz

echo "Decryption process completed."
echo "Stored checksum: $STORED_CHECKSUM"
