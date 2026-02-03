#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="git@github.com:antonpetrovmain/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
BOOTSTRAP_KEY="$HOME/.ssh/id_ed25519_bootstrap"

echo "=== Dotfiles Bootstrap ==="

# Create .ssh directory
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Generate temporary bootstrap key
if [[ -f "$BOOTSTRAP_KEY" ]]; then
  echo "Bootstrap key already exists."
else
  echo "Generating temporary bootstrap SSH key..."
  ssh-keygen -t ed25519 -C "bootstrap-$(hostname)-$(date +%Y%m%d)" -f "$BOOTSTRAP_KEY" -N ""
fi

echo ""
echo "Add this PUBLIC KEY to GitHub (Settings > SSH Keys):"
echo "=================================================="
cat "${BOOTSTRAP_KEY}.pub"
echo "=================================================="
echo ""
read -rp "Press Enter after adding the key to GitHub..." </dev/tty

# Add GitHub to known hosts
ssh-keyscan -t ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null

# Configure SSH to use bootstrap key for GitHub
cat > "$HOME/.ssh/config" <<EOF
Host github.com
    IdentityFile $BOOTSTRAP_KEY
EOF
chmod 600 "$HOME/.ssh/config"

# Test connection
echo "Testing GitHub connection..."
ssh_output=$(ssh -T git@github.com 2>&1 || true)
echo "$ssh_output"
if echo "$ssh_output" | grep -q "successfully authenticated"; then
  echo "GitHub authentication successful!"
else
  echo ""
  echo "GitHub authentication failed. Please verify:"
  echo "  1. The key was added to https://github.com/settings/keys"
  echo "  2. You copied the ENTIRE key including 'ssh-ed25519' prefix"
  exit 1
fi

# Clone dotfiles
if [[ -d "$DOTFILES_DIR" ]]; then
  echo "Dotfiles directory already exists at $DOTFILES_DIR"
else
  echo "Cloning dotfiles..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

echo ""
echo "Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. cd $DOTFILES_DIR"
echo "  2. ./mac-install.sh   # Install packages"
echo "  3. ./install.sh       # Setup configs (will replace bootstrap key)"
echo "  4. Remove the bootstrap key from GitHub"
echo "  5. Add your new permanent key(s) to GitHub"
