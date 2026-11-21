let
  inner =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        noto-fonts
        noto-fonts-color-emoji
        noto-fonts-cjk-sans
      ];
    };
in
{
  flake.nixosModules.fonts = inner;
  flake.darwinModules.fonts = inner;
}
