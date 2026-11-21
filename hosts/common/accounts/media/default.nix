{ ... }:
{
  flake.nixosModules."account-media" =
    {
      config,
      lib,
      ...
    }:
    {
      users.users.media = lib.mkIf (lib.elem "media" config.accounts.activeUsers) {
        isNormalUser = true;
        description = "Shared media account";
        extraGroups =
          let
            ifTheyExist = groups: lib.filter (g: lib.hasAttr g config.users.groups) groups;
          in
          ifTheyExist [
            "audio"
            "video"
            "render"
          ];
      };
    };
}
