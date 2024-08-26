#!/bin/bash

# Function to securely read passphrase
read_passphrase() {
    local passphrase passphrase_confirm

    while true; do
        echo -n "Enter the passphrase for encryption: " >&2
        read -s passphrase
        echo >&2

        echo -n "Confirm the passphrase: " >&2
        read -s passphrase_confirm
        echo >&2

        if [ "$passphrase" = "$passphrase_confirm" ]; then
            echo "$passphrase"
            return 0
        else
            echo "Passphrases do not match. Please try again." >&2
        fi
    done
}

# Check if the vault directory exists
if [ ! -d "./vault" ]; then
    echo "Error: ./vault directory not found."
    exit 1
fi

# Check if there are any files in the vault directory
if [ -z "$(ls -A ./vault)" ]; then
    echo "Error: The vault directory is empty."
    exit 1
fi

# Count the number of files in the vault directory
FILE_COUNT=$(find ./vault -type f | wc -l)

# Read passphrase from stdin if available, otherwise prompt
if [ -t 0 ]; then
    PASSPHRASE=$(read_passphrase)
else
    read -s PASSPHRASE
fi

# Verify that we got a passphrase
if [ -z "$PASSPHRASE" ]; then
    echo "Error: No passphrase provided. Exiting."
    exit 1
fi

# Generate checksum of the vault directory
VAULT_CHECKSUM=$(find ./vault -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)

# Create a tar archive of the vault directory
tar -czf vault_content.tar.gz ./vault

# Prepend the checksum to the tar archive
(echo -n "$VAULT_CHECKSUM"; cat vault_content.tar.gz) > vault.tar.gz
rm vault_content.tar.gz

# Encrypt the tar archive (now including the checksum)
echo "$PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 \
    --symmetric --cipher-algo AES256 --s2k-mode 3 --s2k-count 65011712 \
    --s2k-digest-algo SHA512 --no-symkey-cache \
    --output vault.tar.gz.gpg vault.tar.gz

# Check if encryption was successful
if [ $? -eq 0 ]; then
    echo -e "Encryption successful: vault.tar.gz.gpg"
    # Remove the unencrypted tar file
    rm vault.tar.gz

    # Function to get file size in bytes and convert to MB
    get_file_size_in_mb() {
        local file=$1
        local file_size_bytes
        local file_size_mb

        # Get file size in bytes using appropriate `stat` syntax for the platform
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            file_size_bytes=$(stat -f%z "$file")
        else
            # Linux and other Unix-like systems
            file_size_bytes=$(stat -c%s "$file")
        fi

        # Convert bytes to MB with two decimal places
        file_size_mb=$(echo "scale=2; $file_size_bytes / 1024 / 1024" | bc)

        echo "$file_size_mb"
    }

    ENCRYPTED_SIZE=$(get_file_size_in_mb vault.tar.gz.gpg)

    printf "Files encrypted: %s\n" "$(echo "$FILE_COUNT" | xargs)"
    printf "Vault archive size: %s\n" "$(echo "$ENCRYPTED_SIZE" | xargs)mb"
    printf "Vault checksum: %s\n" "$(echo "$VAULT_CHECKSUM" | xargs)"
else
    echo -e "\nEncryption failed"
    exit 1
fi

