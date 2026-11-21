{
  flake.darwinModules.onedrive =
    { lib, ... }:
    {
      homebrew.enable = lib.mkDefault true;

      homebrew.casks = [
        "onedrive"
      ];
    };

  flake.nixosModules.onedrive =
    { lib, ... }:
    {
      programs.onedrive.enable = lib.mkDefault true;
    };
}
