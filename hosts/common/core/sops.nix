{
  inputs,
  lib,
  secretsLayout,
  ...
}:
let
  nixosSops =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.default ];

      sops = {
        defaultSopsFile = "${inputs.nix-secrets}/${secretsLayout.hostFile config.hostSpec.hostName}";
        validateSopsFiles = false;
        # Only the host's own age key, created by the installer. Never the SSH
        # host key, and never a new key: one would decrypt nothing.
        age = {
          sshKeyPaths = [ ];
          keyFile = "/var/lib/sops-nix/key.txt";
          generateKey = false;
        };
      };
    };

  darwinSops =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.darwinModules.default ];

      sops = {
        defaultSopsFile = "${inputs.nix-secrets}/${secretsLayout.hostFile config.hostSpec.hostName}";
        validateSopsFiles = false;
        age = {
          sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          keyFile = "/var/lib/sops-nix/key.txt";
          generateKey = true;
        };
      };
    };
in
{
  # Where each secret file is in nix-secrets, from its flake's secretsEntry, checked by
  # nixos-bootstrap. Every module that names a secret file takes its path from here.
  _module.args.secretsLayout = inputs.nixos-bootstrap.lib.secretsLayout {
    inherit lib;
    secretsFlake = inputs.nix-secrets;
  };

  flake.nixosModules.core = nixosSops;
  flake.darwinModules.core = darwinSops;
}
