{
  flake.homeModules.core =
    { pkgs, ... }:
    {
      programs.git = {
        enable = true;
        package = pkgs.git;
        lfs.enable = true;

        settings = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          rebase.autoStash = true;
          fetch.prune = true;
          diff.algorithm = "histogram";
          merge.conflictstyle = "zdiff3";
          rerere.enabled = true;
          column.ui = "auto";
          branch.sort = "-committerdate";
        };

        ignores = [
          ".DS_Store"
          ".direnv/"
          "result"
          "result-*"
          "*.swp"
        ];
      };
    };
}
