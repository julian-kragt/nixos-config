{
  self,
  lib,
  ...
}:
let
  pubKeysFor = u: self.lib.custom.genPubKeyList (./. + "/${u}/keys");
  superPubKeys = self.lib.custom.genPubKeyList ./super/keys;
in
{
  flake.nixosModules.account-system-users =
    {
      config,
      ...
    }:
    {
      users.users =
        lib.genAttrs config.accounts.activeUsers (u: {
          home = "/home/${u}";
          openssh.authorizedKeys.keys = pubKeysFor u ++ superPubKeys;
        }
        # No secret when nix-secrets' user templates have no hashedPassword.
        // lib.optionalAttrs (config.sops.secrets ? "passwords/${u}") {
          hashedPasswordFile = config.sops.secrets."passwords/${u}".path;
        })
        // lib.optionalAttrs (config.accounts.activeUsers != [ ]) {
          # Root inherits the primary user's keys for remote deploy access.
          root.openssh.authorizedKeys.keys =
            config.users.users.${config.hostSpec.primaryUser}.openssh.authorizedKeys.keys;
        };
    };

  flake.darwinModules.account-system-users =
    {
      config,
      pkgs,
      ...
    }:
    {
      users.users = lib.genAttrs config.accounts.activeUsers (u: {
        shell = pkgs.zsh;
        home = "/Users/${u}";
        openssh.authorizedKeys.keys = pubKeysFor u ++ superPubKeys;
      });
    };
}
