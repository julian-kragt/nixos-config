# `bootstrapEntries.<host>`: what nixos-bootstrap reads to install a NixOS host
# for the first time, and its generated `<host>-bootstrap` systems. The fields are
# fixed by nixos-bootstrap (its README: "The entry's fields"). Kept apart from the
# config: nothing here is imported by a host, it only reads the evaluated
# nixosConfigurations.
{
  self,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.nixos-bootstrap.flakeModules.default ];

  # The hosts are named because the generated systems' names come from here:
  # mapping over all of self.nixosConfigurations is infinite recursion. wsl has no
  # disko layout, so it isn't listed.
  flake.bootstrapEntries =
    lib.mapAttrs
      (
        host:
        { config, ... }:
        {
          system = config.nixpkgs.hostPlatform.system;
          diskoDevices = config.disko.devices;
          rootAuthorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
          hardwareConfigPath = "hosts/nixos/${host}/hardware-configuration.nix";
          users = config.users.users;
        }
      )
      {
        inherit (self.nixosConfigurations) atlas broadway;
      };
}
