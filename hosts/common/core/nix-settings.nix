let
  inner =
    {
      config,
      ...
    }:
    {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "pipe-operators"
        ];
        auto-optimise-store = true;
        trusted-users = [
          "root"
          "@wheel"
          config.hostSpec.primaryUser
        ];
        warn-dirty = false;

        extra-substituters = [
          "https://nix-community.cachix.org"
          "https://devenv.cachix.org"
        ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        ];
      };

      nix.gc = {
        automatic = true;
        options = "--delete-older-than 14d";
      };

      nixpkgs.config.allowUnfree = true;
    };
in
{
  flake.nixosModules.core = inner;
  flake.darwinModules.core = inner;
}
