{
  flake.homeModules.jkragt-common-core-darwin =
    { ... }:
    {
      # Darwin-only HM defaults for jkragt.
      home.sessionVariables = { };
    };
}
