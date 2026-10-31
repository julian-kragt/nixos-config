# macOS counterpart of the zotero home module: nixpkgs' build bundles an EOL, insecure Firefox ESR.
{
  flake.darwinModules.zotero =
    { lib, ... }:
    {
      homebrew.enable = lib.mkDefault true;

      homebrew.casks = [
        "zotero"
      ];
    };
}
