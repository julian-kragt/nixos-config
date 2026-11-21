{
  self,
  ...
}:
{
  flake.darwinModules.host-common =
    {
      lib,
      ...
    }:
    {
      imports = with self.darwinModules; [
        overlays
        nix-homebrew
      ];

      # Defaults that apply to every darwin host.
      # Per-host modules override or extend.

      environment.variables = {
        LANG = lib.mkDefault "en_US.UTF-8";
        LC_ALL = lib.mkDefault "en_US.UTF-8";
      };
    };
}
