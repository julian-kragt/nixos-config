{
  flake.nixosModules.host-wsl =
    { ... }:
    {
      hostSpec = {
        hostName = "wsl";
        primaryUser = "jkragt";
        role = "wsl";
        timeZone = "Europe/Amsterdam";
      };
    };
}
