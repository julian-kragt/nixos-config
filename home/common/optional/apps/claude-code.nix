{
  flake.homeModules.claude-code =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.claude-code
      ];
    };
}
