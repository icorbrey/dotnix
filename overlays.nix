{ inputs, ... }: [
  inputs.nur.overlays.default

  (final: prev: {
    helix = inputs.helix.packages.${prev.system}.default;
  })
]
