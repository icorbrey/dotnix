_default:
    @just --list

# - Defaults to the current hostname.
# - Will fail if the hostname does not have a valid configuration.
# 
# Snapshot and install the current configuration.
install user=shell('whoami') hostname=shell('hostname'): _snapshot (_switch user hostname)

# Read the news.
news user=shell('whoami') hostname=shell('hostname'):
    @home-manager news --flake .#{{user}}@{{hostname}}

# Update the flake's input and install the current configuration.
update user=shell('whoami') hostname=shell('hostname'): _update _snapshot (_switch user hostname)

# Abandon current changes and install the previous configuration.
revert user=shell('whoami') hostname=shell('hostname'): _abandon (_switch user hostname)

_switch user hostname: (_switch-nixos hostname) (_switch-home user hostname)

_switch-nixos hostname:
    @if nix eval .#nixosConfigurations.{{hostname}} --quiet > /dev/null 2>&1; then \
        echo "Applying NixOS config for {{hostname}}"; \
        sudo nixos-rebuild switch --flake .#{{hostname}}; \
    fi

# Switch to the Home Manager flake for the given user and hostname.
_switch-home user hostname:
    @echo "Applying Home Manager config for {{user}}@{{hostname}}"
    @home-manager switch --flake .#{{user}}@{{hostname}} -b backup

_update:
    @nix flake update

# Snapshot the repo in its current state.
_snapshot:
    @jj status > /dev/null 2>&1

# Abandon the current commit
_abandon:
    @jj abandon
