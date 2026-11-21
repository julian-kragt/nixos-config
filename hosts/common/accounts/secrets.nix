{
  inputs,
  lib,
  secretsLayout,
  ...
}:
{
  flake.nixosModules.account-secrets =
    { config, ... }:
    {
      # The file whose template in nix-secrets has hashedPassword; none if neither has.
      sops.secrets = lib.listToAttrs (
        lib.concatMap (
          u:
          let
            file = secretsLayout.passwordFile config.hostSpec.hostName u;
          in
          lib.optional (file != null) {
            name = "passwords/${u}";
            value = {
              sopsFile = "${inputs.nix-secrets}/${file}";
              key = "hashedPassword";
              neededForUsers = true;
            };
          }
        ) (lib.filter (u: config.accounts.users.${u}.secrets) config.accounts.activeUsers)
      );
    };

  flake.darwinModules.account-secrets = { };
}
