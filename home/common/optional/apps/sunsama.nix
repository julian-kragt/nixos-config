# nixpkgs only packages Sunsama for Linux; macOS gets it via the sunsama darwin module (Homebrew cask).
{
  flake.homeModules.sunsama =
    { lib, pkgs, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.sunsama
      ];
    };
}
