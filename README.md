# .nix

My Nix configuration. Enter at your own risk.

## Getting started

Make sure you have Nix installed before starting. Clone the repo and bootstrap
the environment:

```sh
git clone https://github.com/icorbrey/dotnix ~/.nix
cd ~/.nix
nix develop
```

## Installing an existing host

Install an existing host's configuration with `just install` (or `just install
<hostname>` if you're installing a different host's configuration). 

## Initializing a new host

You can initialize a new host with `just init` (or `just init <hostname>` if
you're on a different host). Make sure to add an entry in `flake.nix` and
configure the host at `hosts/<hostname>/home.nix`.

## License

My Nix configuration is distributed under the [MIT license][].

[mit license]: ./LICENSE.md
