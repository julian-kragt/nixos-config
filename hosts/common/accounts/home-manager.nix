{
  self,
  inputs,
  lib,
  ...
}:
let
  homeModuleIfExists =
    name:
    if (self ? homeModules) && (self.homeModules ? ${name}) then [ self.homeModules.${name} ] else [ ];
in
{
  flake.nixosModules.account-home-manager = 
    { config, ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit inputs self;
          hostSpec = config.hostSpec;
        };

        users = lib.genAttrs config.accounts.activeUsers (u: {
            imports = [
              self.homeModules.core
              self.homeModules.core-nixos
              self.homeModules."${u}-common-core"
            ]
              ++ homeModuleIfExists "${u}-common-core-nixos"
              ++ homeModuleIfExists "${u}-nixos";

            home = {
              username = u;
              homeDirectory = "/home/${u}";
              stateVersion = config.hostSpec.stateVersion;
          };
        });
      };
    };

  flake.darwinModules.account-home-manager = 
    { config, ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit inputs self;
          hostSpec = config.hostSpec;
        };

        users = lib.genAttrs config.accounts.activeUsers (u: {
            imports = [
              self.homeModules.core
              self.homeModules."core-darwin"
              self.homeModules."${u}-common-core"
            ]
              ++ homeModuleIfExists "${u}-common-core-${config.hostSpec.hostName}"
              ++ homeModuleIfExists "${u}-${config.hostSpec.hostName}";

            home = {
              username = u;
              homeDirectory = "/Users/${u}";
              stateVersion = config.hostSpec.stateVersion;
          };
        });
      };
    };
}
