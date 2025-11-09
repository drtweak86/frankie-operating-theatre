#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"

echo ">> Git identity"
read -rp "Git user.name  : " GNAME
read -rp "Git user.email : " GEMAIL

git config --global user.name  "$GNAME"
git config --global user.email "$GEMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor "nano"

# Ensure SSH directory exists & safe perms
mkdir -p "${HOME_DIR}/.ssh"
chmod 700 "${HOME_DIR}/.ssh"
chown -R "${USER_NAME}:${USER_NAME}" "${HOME_DIR}/.ssh"

KEY="${HOME_DIR}/.ssh/id_ed25519"
if [[ -f "${KEY}" ]]; then
  echo ">> SSH key already exists: ${KEY}"
else
  read -rp "Optional key label (e.g. ${USER_NAME}@frankie): " LABEL
  sudo -u "${USER_NAME}" ssh-keygen -t ed25519 -a 100 -f "${KEY}" -N "" -C "${LABEL:-$GEMAIL}"
fi

# Start agent & add key (for current shell; login sessions may do this automatically)
eval "$(ssh-agent -s)" >/dev/null
ssh-add "${KEY}"

echo
echo "=== Public key — add this to GitHub → Settings → SSH and GPG keys ==="
echo
cat "${KEY}.pub"
echo
echo "Tip: test with  ssh -T git@github.com  (answer 'yes' on first connect)."
