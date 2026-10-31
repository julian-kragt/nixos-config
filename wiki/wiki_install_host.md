# install-host: how it works

This page explains what `scripts/install-host.sh` does and how the flow works end-to-end.

## Purpose

`install-host.sh` automates provisioning and bootstrapping a NixOS host using your flake-defined host bootstrap config.

It supports three modes:

- **Full flow** (default): install + post-install steps
- **SOPS enrollment only**: `--enroll-sops`
- **Remote deploy only**: `--deploy-remote`

The script is invoked by the `justfile` helpers:

- `just install <host> <ip>`
- `just enroll-sops <host> <ip>`
- `just deploy-remote <host> <ip>`

## Inputs and host mapping

The script expects:

- `<host>`: host directory name under `hosts/nixos/<host>/`
- `<ip>`: target machine IP for SSH/install operations

It validates that:

- `hosts/nixos/<host>/disko.nix` exists (the generic installer bootstrap is generated from it)

Then it builds references into your flake outputs:

- `nixos-config-bootstrap#facts.<host>` and `nixos-config-bootstrap#lib.mkBootstrap` (the sibling `../nixos-config-bootstrap` flake)
- `...hostSpec.primaryUser` (read from the host bootstrap config)

So install behavior is driven by host-specific Nix config, not hardcoded shell logic.

## Runtime behavior (high-level flow)

1. **Parse args and choose mode**
   - default mode is full
   - optional flags switch to partial workflows (`--enroll-sops`, `--deploy-remote`)

2. **Load and validate host bootstrap config**
   - resolves repo root
   - checks the host has a `disko.nix`
   - prepares flake attribute paths used by `nix eval`

3. **Resolve install policy**
   - host facts (e.g. primary user) come from the bootstrap `hostSpec`
   - policy knobs are script defaults, overridable via env: `GENERATE_HARDWARE`, `ENROLL_SOPS`, `PROVISION_USER_AGE`, `PUSH_SECRETS`, `DEPLOY_FULL`, `SSH_TIMEOUT`, `LUKS_FILE`, `NIX_SECRETS_PATH`, `NIXOS_ANYWHERE_EXTRA`

4. **Run install/provisioning step (full mode)**
   - performs unattended install path (documented in script header as nixos-anywhere based)
   - disk layout comes from the host's `disko.nix`
   - LUKS passphrase is expected from `DISKO_PASSWORD` or interactive prompt
   - secret passphrases are not stored in Nix

5. **SOPS enrollment step (full mode or `--enroll-sops`)**
   - performs post-install host secret enrollment flow
   - aligns with your documented secret model (host key → age recipient → `.sops.yaml` updates/rekey as needed)

6. **Remote deploy step (full mode or `--deploy-remote`)**
   - deploys full configuration remotely after bootstrap/enrollment

## UX/safety helpers inside script

The script includes utility functions for:

- step/status logging (`log_step`, `log_ok`, `log_info`)
- colored action prompts and confirmations (`log_confirm`, `confirm`)
- hard-fail error exits (`die`)
- optional editor opening (`edit`)

It runs with strict bash flags:

- `set -euo pipefail`

This means it exits on first error, on unset variables, and on failed pipeline stages.

## How to run

### Full bootstrap/install flow

```bash
just install <host> <ip>
# or
bash scripts/install-host.sh <host> <ip>
```

### Only SOPS enrollment phase

```bash
just enroll-sops <host> <ip>
# or
bash scripts/install-host.sh <host> <ip> --enroll-sops
```

### Only remote deploy phase

```bash
just deploy-remote <host> <ip>
# or
bash scripts/install-host.sh <host> <ip> --deploy-remote
```

## Preconditions

- host exists at `hosts/nixos/<host>/`
- the host has `host-spec` and `disko.nix` (the generic bootstrap in `nixos-config-bootstrap` reads the host's disko devices and root keys from this flake's `bootstrap.<host>` output; it has no hardware config)
- machine reachable over network/SSH at `<ip>`
- required local tooling available (`nix`, and whatever bootstrap path requires)
- if encrypted disks are used, provide `DISKO_PASSWORD` or be ready to enter it interactively

## Troubleshooting quick checks

- **“host is not a NixOS host with bootstrap.nix”**
  - verify host directory and `bootstrap.nix` path
- **Nix eval failures**
  - confirm `nixos-config-bootstrap#facts.<host>` evaluates
  - validate the host's `hostSpec` evaluates
- **Install reaches disk encryption prompt**
  - set/export `DISKO_PASSWORD` before running, or enter manually
- **Secrets unavailable after install**
  - rerun `--enroll-sops` phase and verify recipient/rekey state in secrets repo
- **Config not applied**
  - run `--deploy-remote` phase and inspect remote build/switch logs
