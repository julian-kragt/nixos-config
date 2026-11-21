{
  flake.homeModules.phpstorm =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.jetbrains.phpstorm
      ];
    };
}
