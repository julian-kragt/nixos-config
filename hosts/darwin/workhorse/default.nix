{
  self,
  inputs,
  ...
}:
{
  flake.darwinConfigurations.workhorse = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit inputs self;
    };
    modules = [
      inputs.home-manager.darwinModules.home-manager
      self.darwinModules.host-workhorse
    ];
  };

  flake.darwinModules.host-workhorse =
    { ... }:
    {
      imports = with self.darwinModules; [
        host-spec
        core
        host-common
        ./mac-settings.nix
        onedrive
        microsoft-apps
        claude-desktop
        sunsama
        zotero
        usersDispatch
        # Work project setup (Homebrew, PHP), from the private repository.
        inputs.nixos-config-private.darwinModules.work
      ];

      nixpkgs.hostPlatform = "aarch64-darwin";
    };
}
