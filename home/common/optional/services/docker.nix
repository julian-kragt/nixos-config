{
  flake.homeModules.docker =
    { pkgs, lib, ... }:
    {
  
  home.packages = [
    pkgs.docker
    pkgs.docker-compose
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    pkgs.colima
  ];

    };
}