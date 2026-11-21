{
  flake.homeModules.chrome =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.google-chrome
      ];
    };
}
