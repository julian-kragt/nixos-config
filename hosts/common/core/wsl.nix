{ inputs, ... }:
let
  wslModule =
    {
      lib,
      config,
      ...
    }:
    {
      imports = [ inputs.nixos-wsl.nixosModules.default ];

      # WSL-only baseline. Skipped on non-WSL hosts via the role gate below.
      config = lib.mkIf (config.hostSpec.role == "wsl") {
        wsl = {
          enable = true;
          defaultUser = config.hostSpec.primaryUser;
          startMenuLaunchers = true;
          # Lets `wsl --shutdown` followed by re-enter pick up changes faster.
          interop.includePath = false;
        };

        # WSL hosts use Microsoft's bootloader; turn off systemd-boot from core.
        boot.loader.systemd-boot.enable = lib.mkForce false;
        boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

        # No firewall by default — Windows handles network.
        networking.firewall.enable = lib.mkForce false;
      };
    };
in
{
  flake.nixosModules.core = wslModule;
}
