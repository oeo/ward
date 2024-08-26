#!/bin/bash

# Check if oathtool is installed
if ! command -v oathtool &> /dev/null; then
    echo "Error: oathtool is not installed. Please install oath-toolkit."
    exit 1
fi

# Check if a secret key is provided
if [ $# -eq 0 ]; then
    echo "Error: No secret key provided."
    echo "Usage: $0 <secret_key>"
    exit 1
fi

# Get the secret key from all arguments
SECRET_KEY="$*"

# Function to validate and process the secret key
process_secret() {
    local secret="$1"
    # Remove spaces
    secret=$(echo "$secret" | tr -d ' ')
    # Convert to uppercase
    secret=$(echo "$secret" | tr '[:lower:]' '[:upper:]')
    # Check if it's a valid base32 string
    if echo "$secret" | grep -qE '^[A-Z2-7]+=*$' && [ ${#secret} -ge 16 ]; then
        echo "$secret"
        return 0
    else
        echo "Error: Invalid secret key. It should be a base32 encoded string (with or without spaces)."
        return 1
    fi
}

# Process the secret key
PROCESSED_SECRET=$(process_secret "$SECRET_KEY")
if [ $? -ne 0 ]; then
    echo "$PROCESSED_SECRET"
    exit 1
fi

# Generate the TOTP code
TOTP_CODE=$(oathtool --totp -b "$PROCESSED_SECRET")

# Print the TOTP code
echo "Your TOTP code is: $TOTP_CODE"
