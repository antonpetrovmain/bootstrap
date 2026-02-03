# Bootstrap

Bootstrap script for setting up new machines without GitHub access.

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/antonpetrovmain/bootstrap/main/bootstrap.sh | bash
```

## What it does

1. Generates a temporary SSH key (`~/.ssh/id_ed25519_bootstrap`)
2. Displays the public key for you to add to GitHub
3. Clones the private dotfiles repository
4. Guides you to run the dotfiles install scripts

## After bootstrap

1. Run `./mac-install.sh` to install packages
2. Run `./install.sh` to set up configs (automatically removes bootstrap key)
3. Remove the bootstrap key from GitHub
4. Add your new permanent key(s) to GitHub
