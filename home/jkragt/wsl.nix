# jkragt on NixOS-WSL (hostname `wsl`).
{ self, ... }:
{
  flake.homeModules.jkragt-wsl =
    { ... }:
    {
      imports = with self.homeModules; [
      ];
    };
}
