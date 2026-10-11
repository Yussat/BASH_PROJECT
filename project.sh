
#!/bin/bash

# ==========================================
# CYBERSECURITY BASH PROJECT
# ==========================================

# Check whether OpenSSL is installed
if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: OpenSSL is not installed."
    exit 1
fi

# Create a directory for project files
mkdir -p project_files

echo "======================================"
echo "     PROJECT BASH"
echo "======================================"

while true; do
    echo
    echo "1. Symmetric Encryption"
    echo "2. Symmetric Decryption"
    echo "3. Generate Keys"
    echo "4. Asymmetric Encryption"
    echo "5. Asymmetric Decryption"
    echo "6. Hash a File"
    echo "7. Digitally Sign a File"
    echo "8. Verify a Signed File"
    echo "9. Exit"
    echo "======================================"
    read -r -p "Choose an option: " choice

    case "$choice" in

        1)
            read -r -p "Enter file to encrypt: " file

            if [[ ! -f "$file" ]]; then
                echo "Error: File not found."
                continue
            fi

            openssl enc -aes-256-cbc -pbkdf2 -iter 1000 -in "$file" -out "$file.enc" \
                -pass pass:"$(openssl rand -hex 32)"

            if [[ $? -eq 0 ]]; then
                echo "Encrypted file: $file.enc"
                echo "IMPORTANT: Save the password separately."
                echo "This demo generated a random password that was not saved."
            fi
            ;;

        2)
            read -r -p "Enter encrypted file: " file
            read -r -s -p "Enter decryption password: " password
            echo

            if [[ ! -f "$file" ]]; then
                echo "Error: File not found."
                unset password
                continue
            fi

            openssl enc -d -aes-256-cbc -pbkdf2 -iter 1000 -in "$file" -out "${file%.enc}.decrypted" \
                -pass pass:"$password"

            if [[ $? -eq 0 ]]; then
                echo "Decrypted file: ${file%.enc}.decrypted"
            else
                echo "Decryption failed. Check the password."
                rm -f "${file%.enc}.decrypted"
            fi

            unset password
            ;;

        3)
            echo "Generating RSA private and public keys..."

            openssl genrsa -out project_files/private_key.pem 2048 &&

            openssl pkey -in project_files/private_key.pem -pubout -out project_files/public_key.pem

            chmod 600 project_files/private_key.pem

            echo "Private key: project_files/private_key.pem"
            echo "Public key: project_files/public_key.pem"
            ;;

        4)
            read -r -p "Enter file to encrypt: " file

            if [[ ! -f "$file" ]]; then
                echo "Error: File not found."
                continue
            fi

            if [[ ! -f project_files/public_key.pem ]]; then
                echo "Generate keys first using option 3."
                continue
            fi

            openssl pkeyutl -encrypt -pubin -inkey project_files/public_key.pem -in "$file" -out "$file.rsa.enc" \
                -pkeyopt rsa_padding_mode:oaep \
                -pkeyopt rsa_oaep_md:sha256

            if [[ $? -eq 0 ]]; then
                echo "Encrypted file: $file.rsa.enc"
            else
                echo "Encryption failed. The input may be too large for RSA."
                rm -f "$file.rsa.enc"
            fi
            ;;

        5)
            read -r -p "Enter RSA-encrypted file: " file

            if [[ ! -f "$file" || ! -f project_files/private_key.pem ]]; then
                echo "Encrypted file or private key not found."
                continue
            fi

            openssl pkeyutl -decrypt -inkey project_files/private_key.pem -in "$file" -out "$file.decrypted" \
                -pkeyopt rsa_padding_mode:oaep \
                -pkeyopt rsa_oaep_md:sha256

            if [[ $? -eq 0 ]]; then
                echo "Decrypted file: $file.decrypted"
            else
                echo "Decryption failed."
                rm -f "$file.decrypted"
            fi
            ;;

        6)
            read -r -p "Enter file to hash: " file

            if [[ ! -f "$file" ]]; then
                echo "Error: File not found."
                continue
            fi

            openssl dgst -sha256 "$file"
            ;;

        7)
            read -r -p "Enter file to sign: " file

            if [[ ! -f "$file" ]]; then
                echo "Error: File not found."
                continue
            fi

            if [[ ! -f project_files/private_key.pem ]]; then
                echo "Generate keys first using option 3."
                continue
            fi

            openssl dgst -sha256 -sign project_files/private_key.pem -out "$file.sig" "$file"

            if [[ $? -eq 0 ]]; then
                echo "Digital signature created: $file.sig"
            else
                echo "Signing failed."
            fi
            ;;

        8)
            read -r -p "Enter original file: " file
            read -r -p "Enter signature file: " signature

            if [[ ! -f "$file" || ! -f "$signature" ]]; then
                echo "File or signature not found."
                continue
            fi

            if [[ ! -f project_files/public_key.pem ]]; then
                echo "Public key not found. Generate keys first."
                continue
            fi

            openssl dgst -sha256 -verify project_files/public_key.pem -signature "$signature" "$file"

            ;;

        9)
            echo "Exiting project bash. Goodbye!"
            break
            ;;

        *)
            echo "Invalid option. Please choose 1-9."
            ;;
    esac
done
