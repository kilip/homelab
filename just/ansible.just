# Ansible: provision the node OS (and k3s in a later phase).
#
# Usage:  just ansible <recipe>        e.g.  just ansible check-test
# Extra ansible-playbook flags can be appended to the check/apply recipes:
#   just ansible check-test -e test_host_ip=10.0.0.50 --tags ssh
#
# Mandatory flow for every change:
#   snapshot -> check-test -> apply-test -> verify -> check-prod -> apply-prod

set working-directory := '../ansible'

playbook := 'playbooks/site.yml'

# Prompt for the sudo password (become). Set HOMELAB_BECOME_FLAG='' for passwordless sudo.
become := env('HOMELAB_BECOME_FLAG', '--ask-become-pass')

# VirtualBox VM name of the test node.
vm_name := env('HOMELAB_TEST_VM', 'homelab-test')

# Lets the community.sops collection find the age key once secrets are introduced.
export SOPS_AGE_KEY_FILE := env('SOPS_AGE_KEY_FILE', justfile_directory() / 'age.key')

# List the recipes of this module (also runs on a bare `just ansible`)
[private]
default:
    @just --list ansible

# Install the collections pinned in requirements.yml into ansible/collections
deps:
    ansible-galaxy collection install -r requirements.yml -p collections

# Upgrade the collections within the version ranges pinned in requirements.yml
deps-upgrade:
    ansible-galaxy collection install -r requirements.yml -p collections --upgrade

# Validate playbook syntax (does not connect to any host)
syntax:
    ansible-playbook {{playbook}} --syntax-check

# Lint playbooks and roles (needs ansible-lint)
lint:
    ansible-lint

# Verify SSH connectivity and Python on a group: test or prod
ping group='test':
    ansible {{group}} -m ansible.builtin.ping

# Take a VirtualBox snapshot of the test VM (do this before every apply-test)
snapshot name=('pre-apply-' + datetime('%Y%m%d-%H%M%S')):
    VBoxManage snapshot "{{vm_name}}" take "{{name}}"

# List the snapshots of the test VM
snapshots:
    VBoxManage snapshot "{{vm_name}}" list

# Dry run on the test VM (--check --diff)
check-test *extra: (_check 'test' extra)

# Apply to the test VM
apply-test *extra: (_apply 'test' extra)

# Dry run on prod, the NUC (--check --diff)
check-prod *extra: (_check 'prod' extra)

# Apply to prod, the NUC. Asks for confirmation first.
[confirm('Apply to PROD (the NUC)? Make sure check-test and apply-test passed and the VM is verified. [y/N]')]
apply-prod *extra: (_apply 'prod' extra)

_check group extra='':
    ansible-playbook {{playbook}} --limit {{group}} --check --diff {{become}} {{extra}}

_apply group extra='':
    ansible-playbook {{playbook}} --limit {{group}} --diff {{become}} {{extra}}
