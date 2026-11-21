{
  flake.homeModules.core-darwin =
    { ... }:
    {
      # Darwin-only HM defaults. Most macOS-specific opinions live here.
      home.sessionVariables = {
        # Align with nix-darwin `environment.variables`; avoids bash/zsh setlocale
        # warnings when SSH or Terminal forwards empty LC_*.
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        # Make Homebrew paths visible in HM-managed shells if/when we adopt brew.
        HOMEBREW_NO_ANALYTICS = "1";
      };
    };
}
