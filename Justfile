# Installation steps
# # https://www.youtube.com/watch?v=Z8BL8mdzWHI&ab_channel=DreamsofAutonomy

# 1.- Install Nix
# sh <(curl -L https://nixos.org/nix/install)

# 2.- Check Nix is working & install neofetch
# nix-shell -p neofetch --run neofetch

# 3.- Install nix-darwin
# sudo -E nix run nix-darwin -- switch --flake ~/.config#david
# sudo darwin-rebuild switch --flake ~/.config#david

# Build the system config and switch to it when running `just` with no args
default: switch

hostname := "david"

### macos
# Build the nix-darwin system configuration without switching to it
[macos]
build target_host=hostname flags="":
  @echo "Building nix-darwin config..."
  nix --extra-experimental-features 'nix-command flakes'  build ".#darwinConfigurations.{{target_host}}.system" {{flags}}

# Build the nix-darwin config with the --show-trace flag set
[macos]
trace target_host=hostname: (build target_host "--show-trace")

# Build the nix-darwin configuration and switch to it
[macos]
switch target_host=hostname: (build target_host)
  @echo "switching to new config for {{target_host}}"
  sudo ./result/sw/bin/darwin-rebuild switch --flake ".#{{target_host}}"