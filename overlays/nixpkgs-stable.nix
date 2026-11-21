# Exposes `pkgs.stable` from the flake input `nixpkgs-stable`.
inputs: final: prev: {
  stable = import inputs.nixpkgs-stable {
    inherit (prev.stdenv.hostPlatform) system;
    # Do not pass unstable `prev.config` wholesale into stable; it can break
    # evaluation (e.g. stdenv/replaceStdenv). Mirror only what stable needs.
    config = {
      allowUnfree = prev.config.allowUnfree or true;
    };
  };
}
