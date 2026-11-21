{
  flake.homeModules.starship =
    { ... }:
    {
      programs.starship = {
        enable = true;
        enableZshIntegration = true;

        settings = {
          nix_shell = {
            symbol = "❄️ ";
            format = "[$symbol$state]($style) ";
          };
        };
      };
    };
}
