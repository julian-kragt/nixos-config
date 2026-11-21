{
  flake.homeModules.firefox =
    {
      inputs,
      lib,
      pkgs,
      config,
      hostSpec,
      ...
    }:
    let
      extra = profile: config.firefox.extraToolbarBookmarks.${profile} or [ ];
    in
    {
      # Bookmarks another module adds to a profile's toolbar, after its localhost entries. Home
      # Manager's bookmarks.settings can't take them: a second toolbar entry makes a second folder.
      options.firefox.extraToolbarBookmarks = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf (lib.types.attrsOf lib.types.str));
        default = { };
        description = "Per profile name, `{ name; url; }` bookmarks to add to the toolbar.";
      };

      config = {
        # The Homebrew Firefox picks its default profile from installs.ini (keyed by the hash of
        # /Applications/Firefox.app) and ignores profiles.ini; without this it creates a fresh
        # profile it cannot register in the read-only profiles.ini ("profile cannot be loaded").
        home.file."Library/Application Support/Firefox/installs.ini" =
          lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
            {
              # Firefox recreates this file on launch, so let home-manager overwrite it.
              force = true;
              text = ''
                [2656FF1E876E9973]
                Default=Profiles/work
                Locked=1
              '';
            };

        programs.firefox = {
          enable = true;
          # On darwin Firefox comes from the Homebrew cask: the nixpkgs bundle is unsigned and macOS
          # privacy (App Data) blocks it from writing to ~/Library/Application Support/Firefox.
          package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.stable.firefox;
          profiles = {
            work = {
              name = "work";
              id = 0;
              isDefault = hostSpec.hostName == "workhorse";
              extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
                bitwarden
                ublock-origin
                sponsorblock
                youtube-shorts-block
              ];
              settings = {
                # Without the nix wrapper, profile-installed extensions are not auto-enabled.
                "extensions.autoDisableScopes" = 0;
                "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
                "browser.bookmarks.addedImportButton" = false;
                "browser.toolbars.bookmarks.visibility" = "always";
                "browser.contextual-password-manager.enabled" = false;
              };
              bookmarks = {
                force = true;
                settings = [
                  {
                    toolbar = true;
                    bookmarks = [
                      {
                        name = "";
                        url = "localhost:1841";
                      }
                      {
                        name = "";
                        url = "localhost:1843";
                      }
                    ]
                    ++ extra "work"
                    ++ [
                      {
                        name = "DB";
                        url = "https://phpmyadmin.test";
                      }
                      {
                        name = "";
                        url = "https://www.chatgpt.com";
                      }
                    ];
                  }
                ];
              };
            };
            cove = {
              name = "cove";
              id = 1;
              isDefault = false;
              extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
                bitwarden
                ublock-origin
                sponsorblock
                youtube-shorts-block
              ];
              settings = {
                # Without the nix wrapper, profile-installed extensions are not auto-enabled.
                "extensions.autoDisableScopes" = 0;
                "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
                "browser.bookmarks.addedImportButton" = false;
                "browser.toolbars.bookmarks.visibility" = "always";
                "browser.contextual-password-manager.enabled" = false;
              };
              bookmarks = {
                force = true;
                settings = [
                  {
                    toolbar = true;
                    bookmarks = [
                      {
                        name = "teams";
                        url = "localhost:1841";
                      }
                      {
                        name = "outlook";
                        url = "localhost:1843";
                      }
                    ]
                    ++ extra "cove";
                  }
                ];
              };
            };
          };
        };
      };
    };
}
