{
  flake.homeModules.core =
    { pkgs, ... }:
    {
      # Avoid `setlocale: LC_*: cannot change locale` when the parent environment
      # (e.g. SSH) exports empty LC_* values; match NixOS `i18n.defaultLocale` in host-common.
      home.sessionVariables = {
        LANG = "en_US.UTF-8";
        LC_COLLATE = "en_US.UTF-8";
        LC_CTYPE = "en_US.UTF-8";
      };

      programs.home-manager.enable = true;

      programs.bat.enable = true;
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };
      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };

      home.packages = with pkgs; [
        coreutils
        curl
        eza
        fd
        jq
        ripgrep
        tree
        unzip
        wget
        yq-go
        devenv
      ];
    };
}
