_default:
    @just --list

# - Defaults to the current hostname.
# - Will fail if the hostname does not have a valid configuration.
# 
# Snapshot and install the current configuration.
install user=shell('whoami') hostname=shell('hostname'): _snapshot (_switch user hostname)

# Install only the Home Manager configuration.
install-home user=shell('whoami') hostname=shell('hostname'): _snapshot (_switch-home user hostname)

# Read the news.
news user=shell('whoami') hostname=shell('hostname'):
    @home-manager news --flake path:.#{{user}}@{{hostname}}

# Update the flake's input and install the current configuration.
update user=shell('whoami') hostname=shell('hostname'): _update _snapshot (_switch user hostname)

# Abandon current changes and install the previous configuration.
revert user=shell('whoami') hostname=shell('hostname'): _abandon (_switch user hostname)

_switch user hostname: (_switch-nixos hostname) (_switch-home user hostname)

_switch-nixos hostname:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f hosts/{{hostname}}/configuration.nix ]; then
        exit 0
    fi
    sudo -v
    ./scripts/run-quiet "Applying NixOS config for {{hostname}}..." -- \
        sudo nixos-rebuild switch --flake path:.#{{hostname}}
    gum log --level info "Applied NixOS config for {{hostname}}"

# Switch to the Home Manager flake for the given user and hostname.
_switch-home user hostname:
    @./scripts/run-quiet "Applying Home Manager config for {{user}}@{{hostname}}..." -- \
        home-manager switch --flake path:.#{{user}}@{{hostname}} -b backup
    @gum log --level info "Applied Home Manager config for {{user}}@{{hostname}}"

_update:
    @./scripts/run-quiet "Updating flake inputs..." -- nix flake update
    @gum log --level info "Updated flake inputs"

# Snapshot the repo in its current state.
_snapshot:
    @./scripts/run-quiet "Snapshotting repo..." -- jj status
    @gum log --level info "Snapshotted repo"

# Abandon the current commit
_abandon:
    @./scripts/run-quiet "Abandoning current commit..." -- jj abandon
    @gum log --level info "Abandoned current commit"
