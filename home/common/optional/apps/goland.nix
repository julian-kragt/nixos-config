{
  flake.homeModules.goland =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.jetbrains.goland
      ];
    };
}
