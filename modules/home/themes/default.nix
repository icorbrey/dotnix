{ lib, target }:
  lib.attrsets.mapAttrs (_: v: v.themes.${target})
    (lib.attrsets.filterAttrs (_: v: v.themes.${target} != null)
      (lib.attrsets.mapAttrs (_: v: v { inherit lib; }) {
        clarity-noir = import ./clarity-noir.nix;
      }))
