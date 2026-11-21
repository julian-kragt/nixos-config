{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;
    };
    modules = [
      inputs.home-manager.nixosModules.home-manager
      self.nixosModules.host-wsl
    ];
  };

  flake.nixosModules.host-wsl =
    { ... }:
    {
      imports = with self.nixosModules; [
        host-spec
        core
        host-common
        host-common-wsl
        usersDispatch
        # No openssh by default — Windows side can already SSH in via WSL.
      ];
    };
}
