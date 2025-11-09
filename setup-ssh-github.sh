#!/usr/bin/env bash
set -euo pipefail

echo "=== Frankie OT: GitHub SSH setup ==="

# Prompt for username
if [ -z "${GIT_USER_NAME:-}" ]; then
  read -rp "Enter your GitHub username: " GIT_USER_NAME
fi

# Prompt for email
if [ -z "${GIT_USER_EMAIL:-}" ]; then
  read -rp "Enter your email associated with GitHub: " GIT_USER_EMAIL
fi

KEY_COMMENT="${GIT_USER_NAME}@github"
KEY_PATH="${HOME}/.ssh/id_ed25519"

# Confirm details
echo
echo "→ Username: ${GIT_USER_NAME}"
echo "→ Email:    ${GIT_USER_EMAIL}"
read -rp "Proceed? (y/N) " confirm
[[ "${confirm,,}" == "y" ]] || { echo "Aborted."; exit 1; }
echo

# Ensure .ssh exists
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

# Generate key if missing
if [ ! -f "${KEY_PATH}" ]; then
  echo "→ Generating SSH key..."
  ssh-keygen -t ed25519 -C "${KEY_COMMENT}" -f "${KEY_PATH}" -N ""
else
  echo "→ SSH key already exists: ${KEY_PATH}"
fi

# Start agent + load key
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
  eval "$(ssh-agent -s)" >/dev/null
fi
ssh-add "${KEY_PATH}" >/dev/null 2>&1 || true

# Print public key
echo
echo "=== COPY THIS INTO: GitHub → Settings → SSH & GPG Keys ==="
echo
cat "${KEY_PATH}.pub"
echo
echo "=========================================================="
echo

# Git identity & SSH preference
git config --global user.name  "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Auto-load key on login
if ! grep -q "FRANKIE_OT_SSH_AGENT" "${HOME}/.bashrc"; then
  cat >> "${HOME}/.bashrc" <<'EOF'

# FRANKIE_OT_SSH_AGENT
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
  eval "$(ssh-agent -s)" >/dev/null
fi
ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1 || true
EOF
fi

# Test connection (won't break script)
echo "Testing GitHub SSH..."
ssh -T git@github.com || true

echo
echo "✅ Done."
echo "   Paste the public key into GitHub and you’re ready to push/pull."
