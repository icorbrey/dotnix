# .nix

My Nix configuration. Enter at your own risk.

```sh
# Set up the repo
jj git clone https://tangled.org/isaaccorbrey.com/dotnix ~/.nix
cd ~/.nix
nix develop

# Initialize a new host
just init # or just init <hostname>

# Install an existing host
just install # or just install <hostname>
```

## Bootstrap a new NixOS host

From the NixOS installer ISO:

```sh
curl -fsSL https://tangled.org/isaaccorbrey.com/dotnix/raw/main/bootstrap.sh | sh
```

Prompts (via [gum]) for host (queried from the flake's `nixosConfigurations`),
user (from matching `homeConfigurations.<user>@<host>`), target disk, swap
size, and password; then partitions, formats, mounts, runs `nixos-install`,
and activates home-manager. The repo lands at `~/.nix` on the installed system,
owned by the selected user.

[gum]: https://github.com/charmbracelet/gum

## License

My Nix configuration is distributed under the [MIT license][].

[mit license]: ./LICENSE.md
