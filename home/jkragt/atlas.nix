# jkragt on nixos atlas — the workstation NixOS host.
{ self, ... }:
{
  flake.homeModules.jkragt-atlas =
    { ... }:
    {
      imports = with self.homeModules; [
        nixvim
      ];
    };
}
