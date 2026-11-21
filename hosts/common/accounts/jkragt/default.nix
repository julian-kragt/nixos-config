{ ... }:
{
  flake.nixosModules."account-jkragt" =
    {
      config,
      lib,
      ...
    }:
    {
      users.users.jkragt = lib.mkIf (lib.elem "jkragt" config.accounts.activeUsers) {
        isNormalUser = true;
        description = "Julian Kragt";
        extraGroups =
          let
            ifTheyExist = groups: lib.filter (group: lib.hasAttr group config.users.groups) groups;
          in
          lib.flatten [
            "wheel"
            (ifTheyExist [
              "audio"
              "video"
              "docker"
              "networkmanager"
              "scanner"
              "lp"
            ])
          ];
      };
    };

  flake.darwinModules."account-jkragt" =
    {
      config,
      lib,
      ...
    }:
    {
      users.users.jkragt = lib.mkIf (lib.elem "jkragt" config.accounts.activeUsers) {
        description = "Julian Kragt";
      };
    };
}
