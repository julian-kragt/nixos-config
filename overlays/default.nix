# Orchestrates `nixpkgs.overlays` for every Darwin / NixOS host via host-common.
{
  inputs,
  ...
}:
let
  stableOverlay = import ./nixpkgs-stable.nix inputs;
in
{
  flake.darwinModules.overlays =
    { ... }:
    {
      nixpkgs.overlays = [ stableOverlay ];
    };

  flake.nixosModules.overlays =
    { ... }:
    {
      nixpkgs.overlays = [ stableOverlay ];
    };
}
