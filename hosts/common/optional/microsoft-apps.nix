# Microsoft Word and Teams are not packaged for macOS in nixpkgs; install them as Homebrew casks.
{
  flake.darwinModules.microsoft-apps =
    { lib, ... }:
    {
      homebrew.enable = lib.mkDefault true;

      homebrew.casks = [
        "microsoft-word"
        "microsoft-powerpoint"
        "microsoft-teams"
      ];
    };
}
