#!/usr/bin/env bash
set -euo pipefail

DOTFILES_REPO="git@github.com:antonpetrovmain/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
BOOTSTRAP_KEY="$HOME/.ssh/id_ed25519_bootstrap"

echo "=== Dotfiles Bootstrap ==="

# Create .ssh directory
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Add GitHub to known hosts
ssh-keyscan -t ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null

# Check if we already have GitHub access
echo "Checking GitHub access..."
need_ssh_setup=false
if ssh -T git@github.com </dev/null 2>&1 | grep -q "successfully authenticated"; then
  echo "GitHub access already configured!"
else
  need_ssh_setup=true
fi

# Check if Xcode CLT is needed (macOS only)
need_xcode=false
if [[ "$(uname -s)" == "Darwin" ]] && ! xcode-select -p &>/dev/null; then
  need_xcode=true
fi

# Start Xcode install and do SSH setup in parallel
if [[ "$need_xcode" == true ]]; then
  echo "Installing Xcode Command Line Tools..."
  echo "A dialog window should appear - click 'Install' to continue." >/dev/tty
  xcode-select --install
fi

if [[ "$need_ssh_setup" == true ]]; then
  # Generate temporary bootstrap key
  if [[ -f "$BOOTSTRAP_KEY" ]]; then
    echo "Bootstrap key already exists."
  else
    echo "Generating temporary bootstrap SSH key..."
    ssh-keygen -t ed25519 -C "bootstrap-$(hostname)-$(date +%Y%m%d)" -f "$BOOTSTRAP_KEY" -N ""
  fi

  # Configure SSH to use bootstrap key for GitHub
  cat > "$HOME/.ssh/config" <<EOF
Host github.com
    IdentityFile $BOOTSTRAP_KEY
EOF
  chmod 600 "$HOME/.ssh/config"

  echo ""
  echo "Add this PUBLIC KEY to GitHub (Settings > SSH Keys):"
  echo "=================================================="
  cat "${BOOTSTRAP_KEY}.pub"
  echo "=================================================="
fi

# Wait for both to complete
if [[ "$need_xcode" == true ]] && [[ "$need_ssh_setup" == true ]]; then
  echo ""
  echo "Press Enter after BOTH:" >/dev/tty
  echo "  1. Xcode CLT installation completes" >/dev/tty
  echo "  2. SSH key is added to GitHub" >/dev/tty
  read -r </dev/tty
elif [[ "$need_xcode" == true ]]; then
  echo ""
  echo "Press Enter after Xcode CLT installation completes..." >/dev/tty
  read -r </dev/tty
elif [[ "$need_ssh_setup" == true ]]; then
  echo ""
  echo "Press Enter after adding the key to GitHub..." >/dev/tty
  read -r </dev/tty
fi

# Test SSH connection if we set it up
if [[ "$need_ssh_setup" == true ]]; then
  echo "Testing GitHub connection..."
  ssh_output=$(ssh -T git@github.com </dev/null 2>&1 || true)
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
