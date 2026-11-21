# Pure helpers: `{ inputs, lib } -> attrset`. Wired into `flake.lib.custom` by
# `lib/default.nix`.
{
  inputs,
  lib,
  ...
}:
let
  flakeRoot = ../.;
in
rec {
  relativeToRoot = lib.path.append flakeRoot;

  scanPaths =
    path:
    builtins.map (f: path + "/${f}") (
      builtins.attrNames (
        lib.filterAttrs (
          name: type:
          (type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix") || type == "directory"
        ) (builtins.readDir path)
      )
    );

  scanPathsFilterPlatform =
    platform: path:
    let
      otherPlatform = if platform == "darwin" then "nixos" else "darwin";
      excludedNames = [
        "default.nix"
        "${otherPlatform}.nix"
      ];
    in
    builtins.map (f: path + "/${f}") (
      builtins.attrNames (
        lib.filterAttrs (
          name: type:
          (type == "regular" && lib.hasSuffix ".nix" name && !(builtins.elem name excludedNames))
          || type == "directory"
        ) (builtins.readDir path)
      )
    );

  # A user lives on a host iff home/<user>/<host>.nix exists.
  usersForHost =
    host:
    builtins.readDir (relativeToRoot "home")
    |> lib.filterAttrs (n: t: t == "directory" && n != "common")
    |> builtins.attrNames
    |> lib.filter (u: builtins.pathExists (relativeToRoot "home/${u}/${host}.nix"));

  genPubKeyList =
    dir:
    if builtins.pathExists dir then
      let
        files = lib.filesystem.listFilesRecursive dir;
        pubKeyFiles = builtins.filter (f: lib.hasSuffix ".pub" (toString f)) files;
      in
      map (f: lib.removeSuffix "\n" (builtins.readFile f)) pubKeyFiles
    else
      [ ];

  mkHost =
    {
      host,
      platform,
      modules ? [ ],
      specialArgs ? { },
    }:
    let
      builder =
        if platform == "darwin" then inputs.nix-darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
      hmModule =
        if platform == "darwin" then
          inputs.home-manager.darwinModules.home-manager
        else
          inputs.home-manager.nixosModules.home-manager;
    in
    builder {
      specialArgs = {
        inherit inputs;
      }
      // specialArgs;
      modules = [
        hmModule
        (relativeToRoot "modules/host-spec.nix")
        (relativeToRoot "hosts/common")
        (relativeToRoot "hosts/${platform}/common")
        (relativeToRoot "hosts/${platform}/${host}")
      ]
      ++ modules;
    };
}
