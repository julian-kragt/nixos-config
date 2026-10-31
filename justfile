# nix-config justfile

[private]
default:
    @just --list

# Enter the dev shell (or rely on direnv).
dev:
    nix develop

# Format every .nix file using the flake formatter (`nix fmt`).
# Passing explicit paths avoids bare `nix fmt`, which can hang or run very long.
fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ -f flake.nix ]] || { echo "just fmt: run from the directory that contains flake.nix (usually ./config)" >&2; exit 1; }
    mapfile -t files < <(find . \( -path ./result -o -path ./.git \) -prune -o -name '*.nix' -print)
    [[ ${#files[@]} -gt 0 ]] || exit 0
    exec nix fmt -- "${files[@]}"

# Run nix flake check across all configurations (all systems in flake).
check:
    nix flake check --keep-going --show-trace --all-systems

# Inspect every flake output (sanity-check auto-discovery).
show:
    nix flake show

# Rebuild a host. Defaults to current hostname; auto-detects darwin vs linux.
# Pass the flake output name only: `just rebuild workhorse`, not `just rebuild host=workhorse`
# (the latter is parsed as a single argument and breaks --flake ".#…").
rebuild host=`hostname -s`:
    #!/usr/bin/env bash
    set -euo pipefail
    host="{{host}}"
    if [[ "$host" == host=* ]]; then
      host="${host#host=}"
    fi
    if [[ "$(uname)" == "Darwin" ]]; then
      sudo darwin-rebuild switch --flake ".#$host"
    else
      sudo nixos-rebuild switch --flake ".#$host"
    fi

# Provision a fresh NixOS host (Linux only; uses the generic bootstrap config).
install host ip:
    bash scripts/install-host.sh {{host}} {{ip}}

# SOPS enrollment only (Phases 5-7).
enroll-sops host ip:
    bash scripts/install-host.sh {{host}} {{ip}} --enroll-sops

# Full config remote deploy only (Phase 8).
deploy-remote host ip:
    bash scripts/install-host.sh {{host}} {{ip}} --deploy-remote

# Update one or more flake inputs (no args = update everything).
update *inputs:
    nix flake update {{inputs}}

# Print the users wired onto a given host (filesystem-derived).
users host:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in home/*/{{host}}.nix; do
      [[ -f "$f" ]] && basename "$(dirname "$f")"
    done
