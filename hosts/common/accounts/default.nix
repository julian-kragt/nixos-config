{
  self,
  lib,
  ...
}:
let
  # `isLinux` is true only for `nixosModules.usersDispatch`. It stays a
  # static wrapper parameter (not `pkgs.stdenv.isLinux`) because the value
  # is used inside `imports`, and `imports` cannot depend on `pkgs` (the
  # module system supplies it via `_module.args` after imports are read).
  mkDispatcher =
    { isLinux }:
    {
      config,
      ...
    }:
    let
      systemModulesAttr = if isLinux then "nixosModules" else "darwinModules";

      userDirs =
        builtins.readDir ../../../home
        |> (lib.filterAttrs (_: t: t == "directory"))
        |> builtins.attrNames
        |> (lib.filter (n: n != "common"));

      # Evaluated lazily in `config`; safe to depend on `config.hostSpec`.
      activeUsers = self.lib.custom.usersForHost config.hostSpec.hostName;

      flakeModuleIfExists =
        name: if self.${systemModulesAttr} ? ${name} then [ self.${systemModulesAttr}.${name} ] else [ ];

      accountImports = lib.concatMap (u: flakeModuleIfExists "account-${u}") userDirs;
    in
    {
      # All wiring lives in sibling files (system-users.nix, home-manager.nix,
      # secrets.nix) and per-user fragments (jkragt/, media/). They self-gate
      # on `config.accounts.activeUsers`, which this dispatcher sets below.
      imports =
        accountImports
        ++ [
          self.${systemModulesAttr}.account-system-users
          self.${systemModulesAttr}.account-home-manager
          self.${systemModulesAttr}.account-secrets
        ];

      options.accounts.activeUsers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Users active on this host (set by the dispatcher; read by sibling account-* modules).";
      };

      options.accounts.users = lib.mkOption {
        description = ''
          Per-user policy. Keys are the active users (home/<u>/<hostName>.nix
          exists); set an entry only to override a default.
        '';
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.secrets = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Password comes from host-users/<hostName>-<user>.yaml; false leaves the account without a password.";
            };
          }
        );
      };

      config.accounts.activeUsers = activeUsers;
      config.accounts.users = lib.genAttrs activeUsers (_: { });
    };
in
{
  flake.nixosModules.usersDispatch = mkDispatcher { isLinux = true; };
  flake.darwinModules.usersDispatch = mkDispatcher { isLinux = false; };
}
