{
  flake.darwinModules.host-workhorse =
    { ... }:
    {
      hostSpec = {
        hostName = "workhorse";
        primaryUser = "jkragt";
        role = "workstation";
        timeZone = "Europe/Amsterdam";
      };
    };
}
