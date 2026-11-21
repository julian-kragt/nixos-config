{
  flake.nixosModules.host-atlas-spec =
    { ... }:
    {
      hostSpec = {
        hostName = "atlas";
        primaryUser = "jkragt";
        role = "workstation";
        timeZone = "Europe/Amsterdam";
      };
    };
}
