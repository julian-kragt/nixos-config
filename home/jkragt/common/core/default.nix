{
  flake.homeModules.jkragt-common-core =
    { ... }:
    {
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
}
