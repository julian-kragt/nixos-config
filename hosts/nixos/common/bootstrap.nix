# `nix eval .#bootstrap.<host>`: what nixos-config-bootstrap needs to install a
# NixOS host. A stable contract: change fields only together with that project.
#
#   diskoDevices        the host's disko.devices (disk layout)
#   rootAuthorizedKeys  root's SSH keys (the primary user's keys + super)
#   hardwareConfigPath  where the generated hardware config goes, relative to this flake
{
  self,
  lib,
  ...
}:
let
  hosts =
    builtins.readDir ../.
    |> lib.filterAttrs (name: type: type == "directory" && name != "common")
    |> lib.attrNames;
in
{
  flake.bootstrap = lib.genAttrs hosts (
    host:
    let
      config = self.nixosConfigurations.${host}.config;
    in
    {
      diskoDevices = config.disko.devices;
      rootAuthorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
      hardwareConfigPath = "hosts/nixos/${host}/hardware-configuration.nix";
    }
  );
}
