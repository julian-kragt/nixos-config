# Secrets Management

This page explains, in simple terms, how secrets are handled between `nixos-config` and `nix-secrets`.

## What these two repositories do

- `nixos-config` contains the machine and user configuration.
- `nix-secrets` contains the encrypted secret values.
- The two repos work together so the configuration can reference secrets without storing them in plain text.

## The basic idea

Secrets are stored in `nix-secrets` as encrypted YAML files.
They are encrypted with:

- `sops-nix`
- `age` keys

This means the files can be committed to GitHub safely, but only the right keys can decrypt them.

## File layout in `nix-secrets`

The secret repo uses a simple layout:

- `.sops.yaml` — defines which keys may decrypt which files
- `hosts/<host>.yaml` — host-specific secrets
- `host-users/<host>-<user>.yaml` — user-specific secrets for one host

There is no top-level `sops/` folder. The encrypted YAML files live directly in the repository.

## How `nixos-config` uses the secrets

From the `nixos-config` README:

- The main config repo points to the sibling `nix-secrets` repo.
- `nixos-config` reads `host-users/<host>-<username>.yaml` for the `hashedPassword` field.
- That value is used as `users.users.<name>.hashedPasswordFile`.
- This means the login password hash is stored in the secrets repo, not in the config repo.

In practice:

- `hosts/<host>.yaml` is for secrets only one machine should see.
- `host-users/<host>-<user>.yaml` is for per-user secret values such as the hashed login password.

## How access works

The `.sops.yaml` file defines which age recipients can decrypt each file.

Example from the repo:

- `host-users/atlas-jkragt.yaml` can be decrypted by the `atlas` host key and the user key
- `host-users/workhorse-jkragt.yaml` can be decrypted by the `workhorse` host key and the user key
- `hosts/workhorse.yaml` can be decrypted by the host key for `workhorse`
- `hosts/atlas.yaml` can be decrypted by the host key for `atlas`

So:

- your personal key can open your user secrets
- each host has its own host key for host secrets

## Editing secrets

The repositories provide helper commands to make editing easier.

From `nixos-config`:

- `just secrets-edit hosts/<host>.yaml`
- `just secrets-edit host-users/<host>-<user>.yaml`

From `nix-secrets`:

- `just edit-host-user <host> <user>`
- `just edit-host <host>`
- `just rekey`

These commands open the encrypted file through `sops` so the data is decrypted only while editing.

## How secret keys are set up

### User key

The user key is based on an Ed25519 SSH key.
The repo converts the SSH public key to an age recipient.
That recipient is stored in `.sops.yaml` as `&user_jkragt`.

### Host key

When a NixOS host is installed, the install script can:

- generate a fresh Ed25519 host key
- convert it to an age recipient
- add it to `.sops.yaml`
- rekey the matching encrypted files

This means each host gets access only to the secrets it should have.

## Bootstrap flow

A simplified flow looks like this:

1. Create or update the secret in `nix-secrets`.
2. Encrypt it with `sops`.
3. Make sure the right age recipient is listed in `.sops.yaml`.
4. Re-key the affected files if recipients changed.
5. Use the secret from `nixos-config` in the system configuration.

## Example: NixOS login password

The repo README explains that `host-users/<host>-<username>.yaml` contains a `hashedPassword` field.

Important details:

- it is a SHA-512 crypt hash
- it is not plaintext
- it is used for `users.users.<name>.hashedPasswordFile`

So the password itself is never stored in plain text.
Only the hash is stored, encrypted in the secrets repo.

## Safety rules

Do not commit:

- your SSH private key
- `~/.config/sops/age/keys.txt`

Also keep the secrets repo private, because the recipient list in `.sops.yaml` reveals which machines and users can decrypt secrets.

## Short version

- `nixos-config` is the system configuration repo.
- `nix-secrets` is the encrypted secrets repo.
- `sops` and `age` protect the secret files.
- user secrets and host secrets are separated.
- `nixos-config` reads the secrets during system setup.
- helper commands make editing and re-keying easier.

## Good places to look in the repos

- `nix-secrets/README.md`
- `nix-secrets/.sops.yaml`
- `nix-secrets/justfile`
- `nixos-config/README.md`
