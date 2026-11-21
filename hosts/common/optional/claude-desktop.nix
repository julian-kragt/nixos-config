# Claude Desktop is not packaged in nixpkgs; install it as a Homebrew cask.
{
  flake.darwinModules.claude-desktop =
    { lib, ... }:
    {
      homebrew.enable = lib.mkDefault true;

      homebrew.casks = [
        "claude"
      ];
    };
}
