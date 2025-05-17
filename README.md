# .nix

My Nix configuration. Enter at your own risk.

```sh
# Set up the repo
git clone https://github.com/icorbrey/dotnix ~/.nix
cd ~/.nix
nix develop

# Initialize a new host
just init # or just init <hostname>

# Install an existing host
just install # or just install <hostname>
```
## License

My Nix configuration is distributed under the [MIT license][].

[mit license]: ./LICENSE.md
