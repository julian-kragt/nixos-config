{
  flake.homeModules.media-common-core =
    { ... }:
    {
      programs.git.settings.user = {
        name = "media";
        email = "media@example.com";
      };

      home.sessionVariables.EDITOR = "nvim";
    };
}
