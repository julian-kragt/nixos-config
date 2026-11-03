# `bootstrap.<host>`: the mapper nixos-bootstrap reads to install a NixOS host
# for the first time. The fields are fixed by nixos-bootstrap (its README:
# "The mapper"). Kept apart from the config: nothing here is imported by a host,
# it only reads the evaluated nixosConfigurations.
{
  self,
  lib,
  ...
}:
let
  # NixOS hosts with a disko layout; wsl has none.
  hosts = lib.filterAttrs (
    _: c: c.config ? disko && c.config.disko.devices.disk != { }
  ) self.nixosConfigurations;
in
{
  flake.bootstrap = lib.mapAttrs (
    host:
    { config, ... }:
    {
      system = config.nixpkgs.hostPlatform.system;
      diskoDevices = config.disko.devices;
      rootAuthorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
      hardwareConfigPath = "hosts/nixos/${host}/hardware-configuration.nix";
      users = config.users.users;
    }
  ) hosts;
}
