_default:
    @just --list

# - Defaults to the current hostname.
# - Will fail if the hostname does not have a valid configuration.
# 
# Snapshot and install the current configuration.
install hostname=shell('hostname'): _snapshot (_switch hostname)

# Abandon current changes and install the previous configuration.
revert hostname=shell('hostname'): _abandon (_switch hostname)

# # Initialize configuration for the given host.
# init hostname=shell('hostname') force="false": (_check-init hostname force) _snapshot (_init-host hostname) _snapshot

# _check-init hostname force:
#     #!/bin/bash
#     if [ -d "hosts/{{hostname}}" ] && [ "{{force}}" != "true" ]; then
#         echo "Error: Host \`{{hostname}}\` already exists. Use \`just init --force=true\` to override." >&2
#         exit 1
#     fi

# _init-host hostname:
#     #!/bin/bash
#     mkdir -p hosts/{{hostname}}
#     cp templates/hosts/home.nix hosts/{{hostname}}/home.nix
#     echo "Host \`{{hostname}}\` initialized. Be sure to update \`./flake.nix\`."

# Switch to the Home Manager flake for the given hostname.
_switch hostname:
    @home-manager switch --flake .#{{hostname}} -b backup

# Snapshot the repo in its current state.
_snapshot:
    @jj status > /dev/null 2>&1

# Abandon the current commit
_abandon:
    @jj abandon
