# macOS counterpart of the sunsama home module: nixpkgs only ships the Linux build.
{
  flake.darwinModules.sunsama =
    { lib, ... }:
    {
      homebrew.enable = lib.mkDefault true;

      homebrew.casks = [
        "sunsama"
      ];
    };
}
