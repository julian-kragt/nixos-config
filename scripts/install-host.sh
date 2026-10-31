#!/usr/bin/env bash
# install-host.sh — unattended NixOS install via nixos-anywhere + post-install SOPS enrollment.
#
# Usage:
#   scripts/install-host.sh <host> <ip>              # full flow
#   scripts/install-host.sh <host> <ip> --enroll-sops
#   scripts/install-host.sh <host> <ip> --deploy-remote
#
# Install policy uses env-overridable defaults; host facts come from the bootstrap hostSpec.
# LUKS passphrase: set DISKO_PASSWORD or enter at prompt (never stored in Nix).
set -euo pipefail

clear

confirm() {
  local prompt="${1:-Are you sure?}"
  read -r -p "$prompt [y/N]: " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

edit() {
  local file="$1"
  "${EDITOR:-vi}" "$file"
}

log_ok() { echo -e "\e[32m✓ $*"; echo -e "\e[0m"; }
log_step() { echo; echo -e "\e[32m==> $*"; echo -e "\e[0m"; }
die() { echo -e "\e[31merror: $*\e[0m" >&2; exit 1; }
log_action() {
  echo -e "\e[33m========================================================================"
  echo -e "$*"
  echo -e "========================================================================\e[0m"
}
log_info() { echo -e "\e[33m$*\e[0m"; }

log_confirm() {
  echo -e "\e[33m========================================================================"
  echo -e "$1"
  echo -e "========================================================================\e[0m"
  if confirm "$2"; then
    echo -e "\e[32mProceeding\e[0m"
  else
    echo -e "\e[32mCanceling\e[0m"
    exit 1
  fi
}

MODE="full"
HOST=""
IP=""

usage() {
  echo "usage: $0 <host> <ip> [--enroll-sops | --deploy-remote]" >&2
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enroll-sops) MODE="enroll-sops" ;;
    --deploy-remote) MODE="deploy-remote" ;;
    -h | --help) usage ;;
    *)
      if [[ -z "$HOST" ]]; then
        HOST="$1"
      elif [[ -z "$IP" ]]; then
        IP="$1"
      else
        echo "error: unexpected argument: $1" >&2
        usage
      fi
      ;;
  esac
  shift
done

log_step "Configuration"

[[ -n "$HOST" && -n "$IP" ]] || usage

CONFIG_PATH="$(cd "$(dirname "$0")/.." && pwd)"
cd "$CONFIG_PATH"

BOOTSTRAP="hosts/nixos/${HOST}/disko.nix"
[[ -f "$BOOTSTRAP" ]] || {
  echo "error: $HOST is not a NixOS host with $BOOTSTRAP" >&2
  exit 1
}

# One generic bootstrap config; the host is its input (read via getEnv, hence --impure).
export BOOTSTRAP_HOST="$HOST"
CFG="#nixosConfigurations.bootstrap.config"

nix_eval_raw() {
  nix eval --impure --raw "$1"
}

nix_eval_bool() {
  [[ "$(nix eval --expr "$1" 2>/dev/null)" == "true" ]]
}

PRIMARY_USER="$(nix eval --impure --raw "${CFG}.hostSpec.primaryUser")"

# Install policy defaults; override via environment.
GENERATE_HARDWARE="${GENERATE_HARDWARE:-true}"
ENROLL_SOPS="${ENROLL_SOPS:-true}"
PROVISION_USER_AGE="${PROVISION_USER_AGE:-true}"
PUSH_SECRETS="${PUSH_SECRETS:-true}"
DEPLOY_FULL="${DEPLOY_FULL:-true}"
SSH_TIMEOUT="${SSH_TIMEOUT:-600}"
LUKS_FILE="${LUKS_FILE:-/tmp/disko-password}"
HW_PATH="hosts/nixos/${HOST}/hardware-configuration.nix"
NIX_SECRETS_PATH="${NIX_SECRETS_PATH:-../nix-secrets}"
read -r -a ANYWHERE_EXTRA <<< "${NIXOS_ANYWHERE_EXTRA:-}"

# Resolve relative nix-secrets path against the config repo.
if [[ "$NIX_SECRETS_PATH" != /* ]]; then
  NIX_SECRETS_PATH="$(cd "$CONFIG_PATH" && cd "$NIX_SECRETS_PATH" && pwd)"
fi

SOPS_YAML="${NIX_SECRETS_PATH}/.sops.yaml"
ANCHOR="host_${HOST}"
USER_ANCHOR="user_${PRIMARY_USER}"
PENDING_AGE_DIR="/var/lib/sops-nix/pending-user-age-keys"
PENDING_AGE_KEY="${PENDING_AGE_DIR}/${PRIMARY_USER}"
SYSTEM_AGE_KEY="/var/lib/sops-nix/key.txt"
USER_AGE_DEST="/home/${PRIMARY_USER}/.config/sops/age/keys.txt"

KNOWN_HOSTS="$(mktemp)"
cleanup() {
  rm -f "$KNOWN_HOSTS"
}
trap cleanup EXIT

# Pre-bootstrap installer may rotate host keys; pin after first boot (Phase 4).
SSH_OPTS=(-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null)

pin_target_host_key() {
  ssh-keygen -R "$IP" 2>/dev/null || true
  : >"$KNOWN_HOSTS"
  ssh-keyscan -t ed25519 -T 10 "$IP" >>"$KNOWN_HOSTS" 2>/dev/null \
    || die "could not pin SSH host key for ${IP}"
  SSH_OPTS=(
    -o ConnectTimeout=10
    -o StrictHostKeyChecking=yes
    -o UserKnownHostsFile="$KNOWN_HOSTS"
    -o GlobalKnownHostsFile=/dev/null
  )
}

ssh_target() {
  ssh "${SSH_OPTS[@]}" "root@${IP}" "$@"
}

# Resolve local operator age identity. Never prints key material.
resolve_user_age_key() {
  if [[ -n "${SOPS_AGE_KEY_FILE:-}" ]]; then
    USER_AGE_KEY_FILE="$SOPS_AGE_KEY_FILE"
  else
    USER_AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"
  fi

  [[ -f "$USER_AGE_KEY_FILE" ]] || die "user age key not found at ${USER_AGE_KEY_FILE}.
Create it from your Ed25519 SSH key in nix-secrets:
  cd ${NIX_SECRETS_PATH} && nix develop -c just user-identity
Or set SOPS_AGE_KEY_FILE to an existing age identity file."

  command -v age-keygen >/dev/null || die "age-keygen not in PATH (enter the flake devShell / direnv)"

  grep -q '^AGE-SECRET-KEY-' "$USER_AGE_KEY_FILE" \
    || die "no AGE-SECRET-KEY in ${USER_AGE_KEY_FILE}"

  USER_AGE_RECIPIENT="$(age-keygen -y "$USER_AGE_KEY_FILE" 2>/dev/null)" \
    || die "age-keygen -y failed for ${USER_AGE_KEY_FILE}"
  [[ "$USER_AGE_RECIPIENT" == age1* ]] || die "invalid age recipient from ${USER_AGE_KEY_FILE}"

  [[ -f "$SOPS_YAML" ]] || die "missing ${SOPS_YAML}"
  expected="$(grep "&${USER_ANCHOR}" "$SOPS_YAML" | sed -E 's/.*&'"${USER_ANCHOR}"'[[:space:]]+(age1[^[:space:]]+).*/\1/' | head -1)"
  [[ -n "$expected" ]] || die "anchor &${USER_ANCHOR} not found in ${SOPS_YAML}"
  [[ "$expected" == "$USER_AGE_RECIPIENT" ]] \
    || die "local age recipient (${USER_AGE_RECIPIENT}) does not match &${USER_ANCHOR} (${expected}) in ${SOPS_YAML}"
}

if [[ -f "$SOPS_YAML" ]] && grep -q "&${ANCHOR}" "$SOPS_YAML"; then
  log_action "\e[31m
  error: There is an SOPS age key set for this host in .sops.yaml
  Adviced to delete.
  \e[0m \e[33"

  read -r -p $'\e[33m Auto delete/Edit/Ignore?\e[0m [d=delete/e=edit/i=ignore]: ' reply

  case "$reply" in
    [Ee])
      "${EDITOR:-vi}" "$SOPS_YAML"
      ;;

    [Dd])
      rm -f "${NIX_SECRETS_PATH}/hosts/${HOST}.yaml"
      # portable in-place delete (GNU/BSD sed differ on -i)
      tmp="$(mktemp)"
      grep -v "&${ANCHOR}" "$SOPS_YAML" >"$tmp"
      mv "$tmp" "$SOPS_YAML"
      ;;
    [Ii])
      log_ok "ignored"
      ;;

    *)
      echo "exit"
      exit 1
      ;;
  esac
fi

log_action "There are a few setup commands that need to be run manually:
  1: \`sudo passwd\`
    For setting up a temporary root password
    This is needed to be able to SSH into the new device."

# --- resolve mode overrides ---
RUN_PREFLIGHT=1
RUN_INSTALL=0
RUN_WAIT=0
RUN_SOPS=0
RUN_PROVISION_AGE=0
RUN_DEPLOY=0
RUN_VALIDATE=0

case "$MODE" in
  full)
    RUN_INSTALL=1
    RUN_WAIT=1
    RUN_SOPS=1
    RUN_PROVISION_AGE=1
    RUN_DEPLOY=1
    RUN_VALIDATE=1
    ;;
  enroll-sops)
    RUN_PREFLIGHT=0
    RUN_WAIT=1
    RUN_SOPS=1
    ;;
  deploy-remote)
    RUN_PREFLIGHT=0
    RUN_WAIT=1
    RUN_PROVISION_AGE=1
    RUN_DEPLOY=1
    RUN_VALIDATE=1
    ;;
esac

nix_eval_bool "$ENROLL_SOPS" || RUN_SOPS=0
nix_eval_bool "$DEPLOY_FULL" || RUN_DEPLOY=0
nix_eval_bool "$PROVISION_USER_AGE" || RUN_PROVISION_AGE=0
# User age key is only needed when a full deploy will run.
[[ "$RUN_DEPLOY" == "1" ]] || RUN_PROVISION_AGE=0

# --- Phase 1-2: preflight ---
if [[ "$RUN_PREFLIGHT" == "1" ]]; then
  log_step "Preflight"

  [[ -d "$NIX_SECRETS_PATH" ]] || die "nix-secrets not found at $NIX_SECRETS_PATH"
  git -C "$NIX_SECRETS_PATH" rev-parse >/dev/null 2>&1 || die "nix-secrets is not a git repo: $NIX_SECRETS_PATH"

  DEVICE="$(nix_eval_raw "${CFG}.disko.devices.disk.main.device")"
  [[ "$DEVICE" != *REPLACE_ME* ]] || die "disko device not configured for $HOST (contains REPLACE_ME)"

  if [[ ! -f "${NIX_SECRETS_PATH}/host-users/${HOST}-${PRIMARY_USER}.yaml" ]]; then
    echo "warn: ${NIX_SECRETS_PATH}/host-users/${HOST}-${PRIMARY_USER}.yaml missing — full deploy may fail"
  fi

  if [[ "$RUN_PROVISION_AGE" == "1" ]]; then
    resolve_user_age_key
    log_ok "User age identity matches &${USER_ANCHOR}"
  fi

  ssh-keygen -R "$IP" 2>/dev/null || true

  ping -c 1 -W 2 "$IP" >/dev/null || die "host $IP unreachable"
  log_ok "Installer reachable"

  ssh_target 'echo ok' >/dev/null || die "SSH to root@${IP} failed"

  ssh_target '
    set -euo pipefail
    command -v nix >/dev/null || { echo "nix missing" >&2; exit 1; }
    command -v lsblk >/dev/null || { echo "lsblk missing" >&2; exit 1; }
    ping -c 1 1.1.1.1 >/dev/null || { echo "no internet" >&2; exit 1; }
  ' || die "remote environment checks failed"
  log_ok "Internet reachable"

  ssh_target "test -b '${DEVICE}'" || die "disk device ${DEVICE} not found on installer"
  log_ok "Disk verified"

  echo
  echo "Expected install disk: ${DEVICE}"
  echo
  ssh_target 'lsblk -d -o NAME,SIZE,MODEL,TYPE'
  echo
  read -rp "Type 'install' to continue: " CONFIRM
  [[ "$CONFIRM" == "install" ]] || die "aborted by user"
  log_ok "User confirmed"

  if [[ -z "${DISKO_PASSWORD:-}" ]]; then
    while true; do
      read -rsp "LUKS passphrase for ${HOST}: " p1
      echo
      read -rsp "Confirm LUKS passphrase for ${HOST}: " p2
      echo

      if [[ -z "$p1" ]]; then
        echo "Password cannot be empty"
        continue
      fi

      if [[ "$p1" != "$p2" ]]; then
        echo "Passwords do not match, try again"
        continue
      fi

      DISKO_PASSWORD="$p1"
      break
    done
  fi
  printf '%s' "$DISKO_PASSWORD" | ssh "${SSH_OPTS[@]}" "root@${IP}" "cat > '${LUKS_FILE}' && chmod 600 '${LUKS_FILE}'"
fi

ALREADY_INSTALLED=0
if ssh_target 'test -f /run/current-system' 2>/dev/null; then
  ALREADY_INSTALLED=1
fi

# --- Phase 3: nixos-anywhere ---
if [[ "$RUN_INSTALL" == "1" && "$ALREADY_INSTALLED" == "0" ]]; then
  log_step "Installing bootstrap for ${HOST} on ${IP}"

  HW_ARGS=()
  if nix_eval_bool "$GENERATE_HARDWARE"; then
    HW_ARGS=(
      --generate-hardware-config
      nixos-generate-config
      "$HW_PATH"
    )
  fi

  # shellcheck disable=SC2086
  nix run github:nix-community/nixos-anywhere -- \
    "${HW_ARGS[@]}" \
    --build-on-remote \
    --flake ".#bootstrap" \
    --target-host "root@${IP}" \
    ${ANYWHERE_EXTRA[@]+"${ANYWHERE_EXTRA[@]}"}

  if nix_eval_bool "$GENERATE_HARDWARE" && [[ -n "$(git status --porcelain -- "$HW_PATH")" ]]; then
    git add -- "$HW_PATH"
    git commit -m "chore(${HOST}): add generated hardware-configuration.nix"
  fi

  log_ok "Installation complete"
  ALREADY_INSTALLED=1
elif [[ "$RUN_INSTALL" == "1" && "$ALREADY_INSTALLED" == "1" ]]; then
  log_ok "Installation skipped (system already installed)"
fi

# --- Phase 4: wait for SSH ---
if [[ "$RUN_WAIT" == "1" ]]; then
  log_step "Waiting for first boot"

  ssh-keygen -R "$IP" 2>/dev/null || true
  # Allow TOFU while polling; pin after the first successful login.
  SSH_OPTS=(-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null)

  deadline=$((SECONDS + SSH_TIMEOUT))
  until ssh "${SSH_OPTS[@]}" "root@${IP}" 'echo ok' 2>/dev/null; do
    [[ "$SECONDS" -lt "$deadline" ]] || die "SSH timeout after ${SSH_TIMEOUT}s"
    sleep 5
  done
  pin_target_host_key
  log_ok "First boot detected (SSH host key pinned)"
fi

# --- Phase 5-7: SOPS enrollment ---
if [[ "$RUN_SOPS" == "1" ]]; then
  log_step "Bootstrapping SOPS"

  [[ -d "$NIX_SECRETS_PATH" ]] || die "nix-secrets not found at $NIX_SECRETS_PATH"
  git -C "$NIX_SECRETS_PATH" rev-parse >/dev/null 2>&1 || die "nix-secrets is not a git repo: $NIX_SECRETS_PATH"

  PUB="$(ssh_target 'cat /etc/ssh/ssh_host_ed25519_key.pub')"
  RECIPIENT="$(echo "$PUB" | ssh-to-age)"
  [[ "$RECIPIENT" == age1* ]] || die "ssh-to-age failed: ${RECIPIENT}"

  existing_age=""
  if grep -q "&${ANCHOR}" "$SOPS_YAML"; then
    existing_age="$(grep "&${ANCHOR}" "$SOPS_YAML" | sed -E 's/.*&'"${ANCHOR}"'[[:space:]]+(age1[^[:space:]]+).*/\1/' | head -1)"
    if [[ -n "$existing_age" && "$existing_age" != "$RECIPIENT" ]]; then
      die "SOPS anchor &${ANCHOR} exists with different recipient (${existing_age}). Remove it manually and re-run."
    fi
    if [[ "$existing_age" == "$RECIPIENT" ]]; then
      log_ok "Age recipient already enrolled"
    fi
  fi

  if ! grep -q "&${ANCHOR}" "$SOPS_YAML"; then
    python3 - <<PYEOF
lines = open("$SOPS_YAML").readlines()
out, inserted = [], False
for line in lines:
    out.append(line)
    if not inserted and line.rstrip() == "keys:":
        out.append(f"  - &${ANCHOR} ${RECIPIENT}\n")
        inserted = True
if not inserted:
    raise SystemExit("could not find keys: in .sops.yaml")
open("$SOPS_YAML", "w").writelines(out)
PYEOF

    if ! grep -q "hosts/${HOST}.yaml" "$SOPS_YAML"; then
      cat >>"$SOPS_YAML" <<YAML
  - path_regex: hosts/${HOST}\\.yaml\$
    key_groups:
      - age:
          - *${ANCHOR}
YAML
    fi
    log_ok "Age recipient generated"
  fi

  HOST_YAML="${NIX_SECRETS_PATH}/hosts/${HOST}.yaml"
  if [[ ! -f "$HOST_YAML" ]]; then
    TEMPLATE="${NIX_SECRETS_PATH}/templates/host.yaml"
    [[ -f "$TEMPLATE" ]] || die "template not found: $TEMPLATE"
    mkdir -p "$(dirname "$HOST_YAML")"
    cp "$TEMPLATE" "$HOST_YAML"
  fi

  if ! grep -q '^[[:space:]]*sops:' "$HOST_YAML"; then
    (cd "$NIX_SECRETS_PATH" && sops --encrypt --in-place "hosts/${HOST}.yaml")
  fi

  NEED_UPDATEKEYS=1
  if [[ -n "$existing_age" && "$existing_age" == "$RECIPIENT" ]]; then
    NEED_UPDATEKEYS=0
  fi

  if [[ "$NEED_UPDATEKEYS" == "1" ]]; then
    (cd "$NIX_SECRETS_PATH" && sops updatekeys -y "hosts/${HOST}.yaml" "host-users/${HOST}-${PRIMARY_USER}.yaml")
    log_ok "Secrets updated"
  fi

  (
    cd "$NIX_SECRETS_PATH"
    if [[ -n "$(git status --porcelain)" ]]; then
      git add -A
      git commit -m "feat(${HOST}): add age recipient"
      if nix_eval_bool "$PUSH_SECRETS"; then
        git push || die "git push to nix-secrets failed"
      fi
      log_ok "Secrets pushed"
    fi
  )

  nix flake update nix-secrets
  if [[ -n "$(git status --porcelain -- flake.lock)" ]]; then
    git add flake.lock
    git commit -m "chore: update nix-secrets flake lock for ${HOST}"
  fi
fi

# --- Phase 7.5: provision user age identity ---
if [[ "$RUN_PROVISION_AGE" == "1" ]]; then
  log_step "Provisioning user age identity"

  resolve_user_age_key

  # Pin if we skipped Phase 4 (should not happen for deploy-remote — WAIT runs).
  if [[ ! -s "$KNOWN_HOSTS" ]]; then
    pin_target_host_key
  fi

  already=0
  if ssh_target "test -f '${USER_AGE_DEST}' && test -f '${SYSTEM_AGE_KEY}'"; then
    remote_recip="$(ssh_target "age-keygen -y '${USER_AGE_DEST}' 2>/dev/null" || true)"
    if [[ "$remote_recip" == "$USER_AGE_RECIPIENT" ]]; then
      if ssh_target "grep -qF '${USER_AGE_RECIPIENT}' '${SYSTEM_AGE_KEY}'"; then
        already=1
      fi
    fi
  fi

  if [[ "$already" == "1" ]]; then
    log_ok "User age identity already present on target"
  else
    # Stream identity over stdin; never put key material in argv or shell history.
    # Stages a root-only pending file and merges into the system sops keyfile.
    # Activation (account-secrets) copies pending → ~/.config/sops/age/keys.txt.
    ssh_target "mkdir -p '${PENDING_AGE_DIR}' /var/lib/sops-nix && chmod 700 /var/lib/sops-nix '${PENDING_AGE_DIR}'" \
      || die "failed to create sops key directories on target"

    # shellcheck disable=SC2029
    cat "$USER_AGE_KEY_FILE" | ssh "${SSH_OPTS[@]}" "root@${IP}" \
      "umask 077; cat > '${PENDING_AGE_KEY}' && chmod 600 '${PENDING_AGE_KEY}'" \
      || die "failed to stage user age key on target"

    ssh_target "
      set -euo pipefail
      umask 077
      mkdir -p /var/lib/sops-nix
      touch '${SYSTEM_AGE_KEY}'
      chmod 600 '${SYSTEM_AGE_KEY}'
      # Annotate with public recipient for idempotent checks (age ignores # comments).
      if ! grep -qF '${USER_AGE_RECIPIENT}' '${SYSTEM_AGE_KEY}' 2>/dev/null; then
        {
          echo \"# public key: ${USER_AGE_RECIPIENT}\"
          grep '^AGE-SECRET-KEY-' '${PENDING_AGE_KEY}' || cat '${PENDING_AGE_KEY}'
        } >> '${SYSTEM_AGE_KEY}'
      fi
      chmod 600 '${SYSTEM_AGE_KEY}' '${PENDING_AGE_KEY}'
    " || die "failed to merge user age identity into ${SYSTEM_AGE_KEY}"

    log_ok "User age identity staged (system keyfile + pending for HM)"
  fi
fi

# --- Phase 8: full deploy ---
if [[ "$RUN_DEPLOY" == "1" ]]; then
  log_step "Deploying full configuration"

  if [[ ! -f "${NIX_SECRETS_PATH}/host-users/${HOST}-${PRIMARY_USER}.yaml" ]]; then
    echo "warn: host-users/${HOST}-${PRIMARY_USER}.yaml missing in nix-secrets — deploy will likely fail"
  fi

  nix run nixpkgs#nixos-rebuild -- \
    --flake ".#${HOST}" \
    --target-host "root@${IP}" \
    --build-host "root@${IP}" \
    switch

  log_ok "Deployment complete"
fi

# --- Phase 9: validation ---
if [[ "$RUN_VALIDATE" == "1" ]]; then
  log_step "Validation"

  ssh_target "
    set -euo pipefail
    echo \"Failed units:\"
    systemctl --failed --no-legend || true
    systemctl is-active sops-nix
    test -f '${SYSTEM_AGE_KEY}'
    test -f '${USER_AGE_DEST}'
    mode=\$(stat -c '%a' '${USER_AGE_DEST}' 2>/dev/null || stat -f '%Lp' '${USER_AGE_DEST}')
    owner=\$(stat -c '%U' '${USER_AGE_DEST}' 2>/dev/null || stat -f '%Su' '${USER_AGE_DEST}')
    test \"\$mode\" = '600'
    test \"\$owner\" = '${PRIMARY_USER}'
    # neededForUsers password secret must exist after activation
    test -r /run/secrets-for-users/passwords/${PRIMARY_USER} \
      || test -r /run/secrets/passwords/${PRIMARY_USER}
    # Pending staging file should be consumed by activation
    ! test -f '${PENDING_AGE_KEY}'
    if systemctl is-failed home-manager-${PRIMARY_USER}.service >/dev/null 2>&1; then
      echo \"home-manager-${PRIMARY_USER}.service is failed\" >&2
      exit 1
    fi
    echo \"nixos-version: \$(nixos-version)\"
  "

  log_ok "Validation complete"
fi

echo
echo "Done."
