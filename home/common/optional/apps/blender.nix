{
  flake.homeModules.blender =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.blender
      ];
    };
}
