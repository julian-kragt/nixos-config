# nixpkgs' Zotero bundles an EOL, insecure Firefox ESR, so macOS gets it via the zotero darwin module (Homebrew cask). On Linux it still needs that ESR allowed.
{
  flake.homeModules.zotero =
    { lib, pkgs, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.zotero
      ];
    };
}
