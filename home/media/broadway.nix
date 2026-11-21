# `media` on broadway. The mere existence of this file activates the user;
# no edit to hosts/nixos/broadway/host-spec.nix needed.
{ self, ... }:
{
  flake.homeModules.media-broadway =
    { ... }:
    {
      imports = with self.homeModules; [
      ];
    };
}
