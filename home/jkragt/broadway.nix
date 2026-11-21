# jkragt on nixos broadway. Thinner than workhorse — no desktop tools.
{ self, ... }:
{
  flake.homeModules.jkragt-broadway =
    { ... }:
    {
      imports = with self.homeModules; [
      ];
    };
}
