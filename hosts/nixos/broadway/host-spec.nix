{
  flake.nixosModules.host-broadway-spec =
    { ... }:
    {
      hostSpec = {
        hostName = "broadway";
        primaryUser = "jkragt";
        role = "server";
        timeZone = "Europe/Amsterdam";
      };
    };
}
