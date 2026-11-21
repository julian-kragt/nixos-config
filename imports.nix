{ ... }:
{
  imports = [
    ./modules/host-spec.nix

    ./home/common/core/baseline.nix
    ./home/common/core/darwin.nix
    ./home/common/core/git.nix
    ./home/common/core/sops.nix
    ./home/common/core/ssh.nix
    ./home/common/core/nixos.nix

    ./home/common/optional/apps/blender.nix
    ./home/common/optional/apps/bruno.nix
    ./home/common/optional/apps/chrome.nix
    ./home/common/optional/apps/cursor.nix
    ./home/common/optional/apps/firefox.nix
    ./home/common/optional/apps/ghostty.nix
    ./home/common/optional/apps/nixvim.nix
    ./home/common/optional/apps/phpstorm.nix
    ./home/common/optional/apps/goland.nix
    ./home/common/optional/apps/slack.nix
    ./home/common/optional/apps/obsidian.nix
    ./home/common/optional/apps/claude-code.nix
    ./home/common/optional/apps/spotify.nix
    ./home/common/optional/apps/sunsama.nix
    ./home/common/optional/apps/zotero.nix
    ./home/common/optional/shell/zsh.nix
    ./home/common/optional/shell/starship.nix

    ./home/common/optional/services/docker.nix

    ./home/common/optional/programs/gh.nix
    ./home/common/optional/programs/zoxide.nix

    ./overlays/default.nix
    ./home/common/optional/desktops/aerospace.nix

    ./home/jkragt/atlas.nix
    ./home/jkragt/broadway.nix
    ./home/jkragt/workhorse.nix
    ./home/jkragt/wsl.nix
    ./home/jkragt/common/core/default.nix
    ./home/jkragt/common/core/darwin.nix
    ./home/jkragt/common/core/nixos.nix

    ./home/media/broadway.nix
    ./home/media/common/core/default.nix

    ./hosts/common/core/darwin.nix
    ./hosts/common/core/nix-settings.nix
    ./hosts/common/core/nixos.nix
    ./hosts/common/core/sops.nix
    ./hosts/common/core/wsl.nix

    ./hosts/common/optional/fonts.nix
    ./hosts/common/optional/openssh.nix
    ./hosts/common/optional/nix-homebrew.nix
    ./hosts/common/optional/onedrive.nix
    ./hosts/common/optional/microsoft-apps.nix
    ./hosts/common/optional/claude-desktop.nix
    ./hosts/common/optional/sunsama.nix
    ./hosts/common/optional/zotero.nix

    ./hosts/common/accounts/default.nix
    ./hosts/common/accounts/system-users.nix
    ./hosts/common/accounts/home-manager.nix
    ./hosts/common/accounts/secrets.nix
    ./hosts/common/accounts/jkragt/default.nix
    ./hosts/common/accounts/media/default.nix

    ./hosts/darwin/common/default.nix
    ./hosts/darwin/workhorse/default.nix
    ./hosts/darwin/workhorse/host-spec.nix

    ./hosts/nixos/common/default.nix
    ./hosts/nixos/atlas/default.nix
    ./hosts/nixos/atlas/host-spec.nix
    ./hosts/nixos/broadway/default.nix
    ./hosts/nixos/broadway/host-spec.nix

    ./hosts/wsl/common/default.nix
    ./hosts/wsl/wsl/default.nix
    ./hosts/wsl/wsl/host-spec.nix
  ];
}
