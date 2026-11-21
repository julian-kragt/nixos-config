{
  flake.homeModules.jkragt-common-core-nixos =
    { ... }:
    {
      # Linux-only HM defaults for jkragt. Add e.g. systemd user services here.
      home.sessionVariables = { };
    };
}
