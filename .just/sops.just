set shell := ["bash", "-euo", "pipefail", "-c"]

key_file := env("SOPS_AGE_KEY_FILE", justfile_directory() / "age.key")

# Fetch age private key from pass store
init-key:
    #!/usr/bin/env bash
    set -euo pipefail
    key_path="{{ key_file }}"
    if [ -f "$key_path" ]; then
        echo "age.key already exists at $key_path, skipping."
        exit 0
    fi
    echo "Fetching age.key from pass hl/age-key to $key_path..."
    mkdir -p "$(dirname "$key_path")"
    pass hl/age-key > "$key_path"
    chmod 600 "$key_path"
    echo "age.key created at $key_path."

# Clean temporary decrypted SOPS files (.decrypted~*)
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Cleaning temporary decrypted files..."
    find "{{ justfile_directory() }}" -name ".decrypted~*" -type f -exec rm -v -f {} + 2>/dev/null || true
    echo "✔ Decrypted files cleanup completed."

