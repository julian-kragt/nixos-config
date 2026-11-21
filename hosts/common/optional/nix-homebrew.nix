# Declarative Homebrew installation (brew CLI + pinned taps) for nix-darwin hosts.
{
  inputs,
  lib,
  ...
}:
{
  flake.darwinModules.nix-homebrew =
    { config, ... }:
    {
      imports = [
        inputs.nix-homebrew.darwinModules.nix-homebrew
      ];

      nix-homebrew = {
        enable = lib.mkDefault true;
        user = lib.mkDefault config.system.primaryUser;
        autoMigrate = lib.mkDefault true;

        taps = {
          "homebrew/homebrew-core" = inputs.homebrew-core;
          "homebrew/homebrew-cask" = inputs.homebrew-cask;
        };
        mutableTaps = lib.mkDefault false;
      };

      homebrew.taps = lib.mkDefault (builtins.attrNames config.nix-homebrew.taps);
    };
}
