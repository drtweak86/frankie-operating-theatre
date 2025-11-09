#!/usr/bin/env bash
set -euo pipefail

read -rp "Git user.name: " GNAME
read -rp "Git user.email: " GEMAIL

git config --global user.name "$GNAME"
git config --global user.email "$GEMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase false

# SSH key
KEY="${HOME}/.ssh/id_ed25519"
if [[ -f "${KEY}" ]]; then
  echo "SSH key already exists at ${KEY}"
else
  read -rp "Enter an optional label for the SSH key (e.g. pi@frankie): " LABEL
  ssh-keygen -t ed25519 -a 100 -f "${KEY}" -N "" -C "${LABEL:-${GEMAIL}}"
fi
eval "$(ssh-agent -s)"
ssh-add "${KEY}"

echo "=== Public key (paste this into GitHub → Settings → SSH and GPG keys) ==="
echo
cat "${KEY}.pub"
echo
echo "Tip: test with 'ssh -T git@github.com' (type 'yes' once)."
