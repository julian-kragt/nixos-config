{
  flake.darwinModules.core =
    {
      pkgs,
      config,
      ...
    }:
    {
      networking.hostName = config.hostSpec.hostName;
      networking.computerName = config.hostSpec.hostName;
      networking.localHostName = config.hostSpec.hostName;

      time.timeZone = config.hostSpec.timeZone;

      environment.systemPackages = with pkgs; [
        curl
        just
      ];

      system.primaryUser = config.hostSpec.primaryUser;

      system.stateVersion = 5;
    };
}
