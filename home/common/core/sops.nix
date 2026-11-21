{ secretsLayout, ... }:
{
  flake.homeModules.core =
    { config, inputs, hostSpec, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = {
        # The shared file where nix-secrets has one, else the one for this host.
        defaultSopsFile = "${inputs.nix-secrets}/${secretsLayout.homeFile hostSpec.hostName config.home.username}";
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        validateSopsFiles = false;

      };
    };
}
