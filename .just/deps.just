set shell := ["bash", "-euo", "pipefail", "-c"]

# Install all mise tools and setup python virtualenv for ansible
install:
    mise install
    @if [ -f "ansible/requirements.txt" ] && [ -s "ansible/requirements.txt" ]; then \
        echo "Installing Ansible dependencies into .venv..."; \
        uv pip install -r ansible/requirements.txt; \
    fi

# Upgrade tools and dependencies
update:
    mise upgrade
