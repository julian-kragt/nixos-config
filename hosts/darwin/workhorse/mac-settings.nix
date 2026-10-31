# macOS system defaults for the workhorse host only.
{
  config,
  lib,
  ...
}:
{
  homebrew.casks = [ "firefox" ];

  system.defaults = {
    controlcenter = {
      BatteryShowPercentage = true;
    };
    dock = {
      appswitcher-all-displays = true;
      autohide = false;
      expose-animation-duration = 0.3;
      expose-group-apps = true;
      mineffect = "genie";
      minimize-to-application = true;
      mru-spaces = false;
      # static-only = true;
      tilesize = 48;
      wvous-bl-corner = 2;
      wvous-tr-corner = 2;

      persistent-apps = [
        { app = "/Applications/Firefox.app"; }
        { app = "/Users/${config.system.primaryUser}/Applications/Home Manager Apps/Slack.app"; }
        { app = "/Users/${config.system.primaryUser}/Applications/Home Manager Apps/Spotify.app"; }
        { app = "/Users/${config.system.primaryUser}/Applications/Home Manager Apps/PhpStorm.app"; }
        { app = "/Users/${config.system.primaryUser}/Applications/Home Manager Apps/Ghostty.app"; }
        { app = "/Users/${config.system.primaryUser}/Applications/Home Manager Apps/Bruno.app"; }
      ];
    };
    finder = {
      _FXShowPosixPathInTitle = true;
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      CreateDesktop = false;
      FXPreferredViewStyle = "clmv";
      NewWindowTarget = "Other";
      NewWindowTargetPath = "/Users/${config.system.primaryUser}/Downloads/";
      ShowExternalHardDrivesOnDesktop = false;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = false;
      ShowStatusBar = true;
    };
    menuExtraClock = {
      Show24Hour = true;
      ShowDate = 1;
    };
    screencapture.target = "clipboard";
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
    spaces.spans-displays = false;
    NSGlobalDomain = {
      "com.apple.swipescrolldirection" = false;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = lib.mkDefault 15;
      KeyRepeat = lib.mkDefault 2;
    };
    WindowManager = {
      GloballyEnabled = true;
      EnableStandardClickToShowDesktop = false;
      EnableTiledWindowMargins = false;
    };
    loginwindow.GuestEnabled = false;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
