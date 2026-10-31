{
  flake.homeModules.claude-obsidian =
    {
      config,
      lib,
      inputs,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.claude-obsidian;
      vaultEnv = ''export CLAUDE_OBSIDIAN_VAULT="''${CLAUDE_OBSIDIAN_VAULT:-${cfg.vaultPath}}"'';

      claude = pkgs.writeShellScriptBin "claude" ''
        ${vaultEnv}
        exec ${pkgs.claude-code}/bin/claude --plugin-dir ${inputs.claude-obsidian} "$@"
      '';

      cli = "${pkgs.python312}/bin/python3 ${inputs.claude-obsidian}/scripts/claude-obsidian.py";

      claude-obsidian = pkgs.writeShellScriptBin "claude-obsidian" ''
        ${vaultEnv}
        exec ${cli} "$@"
      '';

      # Create (empty/missing dir) or adopt (existing dir) the vault, applying
      # the hash from its own dry-run. Never forces; failures only warn.
      setupVault = pkgs.writeShellScript "claude-obsidian-vault" ''
        set -u
        export PATH=${lib.makeBinPath [ pkgs.jq pkgs.coreutils ]}
        vault=${lib.escapeShellArg cfg.vaultPath}

        [ -e "$vault/.claude-obsidian.json" ] && exit 0

        if [ -d "$vault" ] && [ -n "$(ls -A "$vault")" ]; then
          cmd=adopt
        else
          cmd=init
        fi

        args=(--operation-id "$cmd-nix" --generated-at "$(date -u +%Y-%m-%dT%H:%M:%SZ)")
        sha=$(${cli} "$cmd" "$vault" "''${args[@]}" | jq -r .approved_plan_sha256) \
          && [ -n "$sha" ] && [ "$sha" != null ] \
          && ${cli} "$cmd" "$vault" "''${args[@]}" --approved-plan-sha256 "$sha" --apply >/dev/null \
          || echo "claude-obsidian: failed to $cmd $vault" >&2
        exit 0
      '';
    in
    {
      options.programs.claude-obsidian.vaultPath = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/Documents/vault";
        description = "Obsidian vault used by claude-obsidian; created or adopted on activation.";
      };

      config = {
        home.packages = [
          claude
          claude-obsidian
        ];

        home.sessionVariables.CLAUDE_OBSIDIAN_VAULT = cfg.vaultPath;

        home.activation.claude-obsidian-vault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${setupVault}
        '';
      };
    };
}
