{
  flake.homeModules.core-nixos =
    { ... }:
    {
      # Linux-only HM defaults — placeholders today; grow per-feature later.
      home.sessionVariables = { };
    };
}
