{
  self,
  ...
}:
{
  flake.nixosModules.host-common =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ self.nixosModules.overlays ];

      # Defaults that apply to every NixOS host.
      # Per-host modules override or extend.

      boot.loader.systemd-boot.enable = lib.mkDefault true;
      boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
      boot.loader.timeout = lib.mkDefault 5;

      console = {
        keyMap = lib.mkDefault "us";
      };

      i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

      # SSH often forwards empty LC_*; set explicit UTF-8 so bash does not warn on setlocale.
      environment.variables = {
        LANG = lib.mkDefault "en_US.UTF-8";
        LC_COLLATE = lib.mkDefault "en_US.UTF-8";
        LC_CTYPE = lib.mkDefault "en_US.UTF-8";
      };

      services.fwupd.enable = lib.mkDefault true;

      programs.command-not-found.enable = false;

      environment.systemPackages = with pkgs; [
        pciutils
        usbutils
      ];
    };
}
