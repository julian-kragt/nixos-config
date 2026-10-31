{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations.atlas = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;
    };
    modules = [
      inputs.home-manager.nixosModules.home-manager
      self.nixosModules.host-atlas
    ];
  };

  flake.nixosModules.host-atlas =
    { lib, ... }:
    {
      imports = [
        ./disko.nix
        inputs.disko.nixosModules.disko
      ]
      # Absent until the installer has generated it (first install).
      ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix
      ++ (with self.nixosModules; [
        host-spec
        host-atlas-spec
        core
        host-common
        usersDispatch
        openssh
        fonts
      ]);

      # Normally set by hardware-configuration.nix.
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      users.users.root.initialPassword = "test";
    };
}
