# jkragt SSH public keys

Drop one `*.pub` file per key here. The dispatcher reads every `.pub` under this
directory at evaluation time via the shared helper `genPubKeyList` and stuffs them into
`users.users.jkragt.openssh.authorizedKeys.keys` on every host where jkragt
lives.

Keys here are **public** — committing them to git is fine.

Examples:

- `workhorse.pub`   — the ed25519 key from this Mac (`~/.ssh/id_ed25519.pub`)
- `yubikey.pub`  — a FIDO2-resident key
- `broadway.pub` — the per-host key generated on the server itself

To add this Mac's existing pubkey:

```sh
cp ~/.ssh/id_ed25519.pub ./workhorse.pub
```
