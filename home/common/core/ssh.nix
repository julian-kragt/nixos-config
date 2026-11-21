{
  flake.homeModules.core =
    { ... }:
    {
      services.ssh-agent.enable = true;

      programs.ssh = {
        enable = true;

        enableDefaultConfig = false;

        settings = {
          "*" = {
            ForwardAgent = false;
            AddKeysToAgent = "yes";
            IdentityFile = "~/.ssh/id_ed25519";
          };
          "github.com" = {
            ForwardAgent = false;
            IdentitiesOnly = true;
            IdentityFile = "~/.ssh/id_ed25519";
            AddKeysToAgent = "yes";
          };
        };
      };
    };
}
