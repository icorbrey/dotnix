{ inputs, ... }: [
  inputs.niri.overlays.niri
  inputs.nur.overlays.default

  (final: prev: {
    auto-cpufreq = inputs.auto-cpufreq.packages.${prev.system}.default;
    helix = inputs.helix.packages.${prev.system}.default;
  })
]
