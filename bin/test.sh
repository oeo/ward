#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test function
run_test() {
    if eval "$1"; then
        echo -e "${GREEN}[PASS]${NC} $2"
    else
        echo -e "${RED}[FAIL]${NC} $2"
        exit 1
    fi
}

# Setup
echo "Setting up test environment..."
TEST_DIR="$(mktemp -d)"
cp bin/encrypt.sh bin/decrypt.sh bin/verify_integrity.sh "$TEST_DIR/"
cd "$TEST_DIR"
mkdir vault
echo "Test content 1" > vault/test1.md
echo "Test content 2" > vault/test2.txt
echo '{"key": "value"}' > vault/data.json
echo "<root>XML Data</root>" > vault/data.xml

# Use a fixed passphrase for testing
TEST_PASSPHRASE="testpassword123"

# Test encryption
echo "Testing encryption..."
ENCRYPTION_OUTPUT=$(./encrypt.sh <<EOF
$TEST_PASSPHRASE
EOF
)
run_test "echo \"$ENCRYPTION_OUTPUT\" | grep -q 'Encryption successful'" "Encryption script runs without errors"
run_test "[ -f vault.tar.gz.gpg ]" "Encrypted archive is created"
run_test "[ ! -f vault.tar.gz ]" "Temporary tar file is removed"
run_test "echo \"$ENCRYPTION_OUTPUT\" | grep -q 'Files encrypted:'" "Number of encrypted files is displayed"
run_test "echo \"$ENCRYPTION_OUTPUT\" | grep -q 'archive size:'" "Size of encrypted archive is displayed"
run_test "echo \"$ENCRYPTION_OUTPUT\" | grep -q 'checksum:'" "Vault checksum is displayed"

# Test integrity verification
echo "Testing integrity verification..."
VERIFY_OUTPUT=$(echo "$TEST_PASSPHRASE" | ./verify_integrity.sh)
echo "$VERIFY_OUTPUT"
run_test "echo \"$VERIFY_OUTPUT\" | grep -q 'Integrity check passed'" "Integrity verification passes for unchanged vault"

# Test decryption with correct password
echo "Testing decryption with correct password..."
mv vault vault_original
run_test "./decrypt.sh <<< '$TEST_PASSPHRASE'" "Decryption script runs without errors"
run_test "[ -d vault ]" "Vault directory is restored"
run_test "diff -r vault vault_original" "Decrypted contents match original"

# Test modification detection
echo "Testing modification detection..."
echo "Modified content" > vault/test1.md
VERIFY_OUTPUT=$(echo "$TEST_PASSPHRASE" | ./verify_integrity.sh)
echo "$VERIFY_OUTPUT"
run_test "echo \"$VERIFY_OUTPUT\" | grep -q 'Integrity check failed'" "Integrity verification fails for modified vault"

# Restore original content
rm -rf vault
mv vault_original vault

# Remove decrypted files
rm -rf vault

# Test decryption with incorrect password
echo "Testing decryption with incorrect password..."
run_test "! ./decrypt.sh <<< 'wrongpassword'" "Decryption script fails with incorrect password"
run_test "[ ! -d vault ]" "Vault directory is not created with wrong password"

# Cleanup
echo "Cleaning up..."
cd ..
rm -rf "$TEST_DIR"

echo "All tests completed successfully!"

