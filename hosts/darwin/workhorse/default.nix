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
        ./projects/appreo.nix
        onedrive
        microsoft-apps
        claude-desktop
        sunsama
        zotero
        usersDispatch
      ];

      nixpkgs.hostPlatform = "aarch64-darwin";
    };
}
