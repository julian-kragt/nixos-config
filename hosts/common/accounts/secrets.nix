{
  inputs,
  lib,
  ...
}:
{
  flake.nixosModules.account-secrets =
    { config, ... }:
    {
      sops.secrets = lib.listToAttrs (
        map (u: {
          name = "passwords/${u}";
          value = {
            sopsFile = "${inputs.nix-secrets}/host-users/${config.hostSpec.hostName}-${u}.yaml";
            key = "hashedPassword";
            neededForUsers = true;
          };
        }) (lib.filter (u: config.accounts.users.${u}.secrets) config.accounts.activeUsers)
      );
    };

  flake.darwinModules.account-secrets = { };
}
