{ self, ... }:
{
  flake.homeModules.jkragt-workhorse =
    { ... }:
    {
      imports =
        with self.homeModules;
        [
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
          zoxide
          zsh
          starship
        ];

      programs.git = {
        settings.user = {
          name = "Julian Kragt";
          email = "18495180+JulianKragt@users.noreply.github.com";
        };
        includes = [
          {
            condition = "gitdir:~/projects/appreo/";
            contents.user = {
              name = "Julian Kragt";
              email = "julian@w3worx.nl";
            };
          }
        ];
      };
    };
}
