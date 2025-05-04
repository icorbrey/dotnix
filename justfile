_default:
    @just --list

# - Defaults to the current hostname.
# - Will fail if the hostname does not have a valid configuration.
# 
# Snapshot and install the current configuration.
install hostname=shell('hostname'): _snapshot (_switch hostname)

# Initialize configuration for the given host.
init hostname=shell('hostname') force="false": (_check-init hostname force) _snapshot (_init-host hostname) _snapshot

_check-init hostname force:
    #!/usr/bin/env bash
    if [ -d "hosts/{{hostname}}" ] && [ "{{force}}" != "true" ]; then
        echo "Error: Host \`{{hostname}}\` already exists. Use \`just init --force=true\` to override." >&2
        exit 1
    fi

_init-host hostname:
    #!/usr/bin/env bash
    mkdir -p hosts/{{hostname}}
    cp templates/hosts/home.nix hosts/{{hostname}}/home.nix
    echo "Host \`{{hostname}}\` initialized. Be sure to update \`./flake.nix\`."

# Switch to the Home Manager flake for the given hostname.
_switch hostname:
    #!/usr/bin/env bash
    home-manager switch --flake .#{{hostname}}

# Snapshot the repo in its current state.
_snapshot:
    #!/usr/bin/env bash
    jj status > /dev/null 2>&1
