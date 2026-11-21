# Flake-parts module: sets `flake.lib.custom` (attrset of functions).
# Use `self.lib.custom.*`, etc., in dendritic fragments.
#
# Does not run `lib.extend` or `_module.args.lib`; nixpkgs `lib` is unchanged.
{
  inputs,
  lib,
  ...
}:
{
  config.flake.lib.custom = import ./helpers.nix { inherit inputs lib; };
}
