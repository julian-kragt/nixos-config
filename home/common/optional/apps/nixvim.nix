{
  flake.homeModules.nixvim =
    { inputs, pkgs, lib, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      home.packages = [
        inputs.nixvim.packages.${system}.default
      ];

      home.sessionVariables = {
        EDITOR = lib.mkDefault "nvim";
        VISUAL = lib.mkDefault "nvim";
      };
    };
}
