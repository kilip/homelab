set shell := ["bash", "-euo", "pipefail", "-c"]

mod sops '.just/sops.just'

[private]
default:
    @just --list --list-submodules
