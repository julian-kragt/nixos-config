{
  inputs,
  lib,
  ...
}:
{
  imports = [ ./lib/default.nix ];

  # Built-in flake-parts `nixosModules` already uses `types.deferredModule` for
  # dendritic merging. Do NOT import `flake-parts.flakeModules.modules`: that extra
  # pulls in top-level flake output `modules`, which `nix flake check` warns about.

  options.flake = {
    darwinConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = { };
    };
    darwinModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
    };
    homeModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
    };
  };

  config.systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  config.perSystem =
    { system, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        name = "nix-config";
        packages = with pkgs; [
          age
          just
          nixfmt
          nixos-anywhere
          sops
          ssh-to-age
          yq-go
          python3
          gum
          tmux
        ];

        shellHook = ''
          echo "nix-config dev shell"
          just
        '';
      };

      formatter = pkgs.nixfmt;
    };
}
