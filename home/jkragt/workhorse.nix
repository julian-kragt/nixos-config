{ self, inputs, ... }:
{
  flake.homeModules.jkragt-workhorse =
    { ... }:
    {
      imports =
        # Work git email and bookmarks, from the private repository.
        [ inputs.nixos-config-private.homeModules.work ]
        ++ (with self.homeModules; [
          blender
          chrome
          bruno
          cursor
          firefox
          ghostty
          nixvim
          phpstorm
          slack
          spotify
          sunsama
          zotero
          obsidian
          claude-code
          docker
          gh
          zoxide
          zsh
          starship
        ]);

      programs.git = {
        settings.user = {
          name = "Julian Kragt";
          email = "18495180+JulianKragt@users.noreply.github.com";
        };
      };
    };
}
