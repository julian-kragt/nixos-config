# Conventions

## Packages: nixpkgs first, Homebrew last

Use as little Homebrew as possible. Install apps from nixpkgs (`home.packages` in a
`home/common/optional/apps/*.nix` home module) whenever the package builds for the target
platform, including macOS.

Fall back to a Homebrew cask only when nixpkgs has no usable build for the platform (not
packaged, Linux-only, or the darwin build is broken/insecure). In that case, follow the
`sunsama` pattern:

- the home module installs the nixpkgs package on Linux only (`lib.optionals pkgs.stdenv.hostPlatform.isLinux`),
- a matching `flake.darwinModules.<name>` in `hosts/common/optional/` adds the cask,
- a comment at the top of both files says why Homebrew is needed.
