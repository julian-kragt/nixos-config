{
  flake.nixosModules.host-common-wsl =
    { lib, ... }:
    {
      # Defaults for every WSL host. core/wsl.nix already handles the
      # role-gated WSL bootstrap; this module is for things specific to our
      # WSL hosts that aren't appropriate in the global core.

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      networking.useDHCP = lib.mkForce false;
      services.fwupd.enable = lib.mkForce false;

      time.hardwareClockInLocalTime = false;
    };
}
