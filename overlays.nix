{inputs, ...}: [
  inputs.nur.overlays.default

  (final: prev: {
    auto-cpufreq = inputs.auto-cpufreq.packages.${prev.system}.default;
    beads = inputs.beads.packages.${prev.system}.default;
    helix = inputs.helix.packages.${prev.system}.default;
    tuicr = inputs.llm-agents.packages.${prev.system}.tuicr;
  })
]
