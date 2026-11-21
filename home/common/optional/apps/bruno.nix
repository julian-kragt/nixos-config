{
  flake.homeModules.bruno =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.bruno
      ];
    };
}
