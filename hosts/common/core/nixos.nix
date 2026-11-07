{
  flake.nixosModules.core =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      networking.hostName = config.hostSpec.hostName;
      time.timeZone = config.hostSpec.timeZone;

      networking.useDHCP = lib.mkDefault true;
      networking.firewall.enable = lib.mkDefault true;

      boot.tmp.cleanOnBoot = lib.mkDefault true;

      users.mutableUsers = false;

      # Rebuilds fetch the nix-secrets input over SSH from GitHub.
      programs.ssh.knownHosts."github.com".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

      environment.systemPackages = with pkgs; [
        curl
        git
        just
      ];

      system.stateVersion = config.hostSpec.stateVersion;
    };
}
