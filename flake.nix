/*
  Installation steps
  # https://www.youtube.com/watch?v=Z8BL8mdzWHI&ab_channel=DreamsofAutonomy

  1.- Install Nix
  sh <(curl -L https://nixos.org/nix/install)

  2.- Check Nix is working & install neofetch
  nix-shell -p neofetch --run neofetch

  3.- Install nix-darwin
  sudo -E nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/.config/nix#m2pro
  sudo darwin-rebuild switch --flake ~/.config#david
*/

{
  description = "Single-file flake with nix-darwin + Home Manager for host 'david'";

  inputs = {
    # Use nixpkgs-unstable to match nix-darwin master (avoids release-branch mismatch)
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      system = "aarch64-darwin"; # change if needed
      pkgs = import nixpkgs { inherit system; };
      # Use the nix-darwin flake input directly; its `lib.darwinSystem` is used below
      darwin = nix-darwin;
    in
    {

      # Darwin system configuration for host 'david'
      darwinConfigurations."david" = darwin.lib.darwinSystem {
        modules = [
          (
            { config, pkgs, ... }:
            {
              # Primary user on the system
              system.primaryUser = "david";

              nixpkgs.config.allowUnfree = true;
              # Ensure nixpkgs.system is set for modules that expect it
              nixpkgs.system = system;
              # Required by nix-darwin to control stateful defaults and migrations
              system.stateVersion = 6;

              environment.systemPackages = with pkgs; [
                mkalias
                nixfmt
                vscode
                oh-my-posh
                helix
                lazygit
                raycast
                rectangle
                ngrok
                slack
                htop
                stats
                uv
                ruff
                bat
                colorls
                amazon-q-cli
              ];

              # Example mac defaults
              system.defaults = {
                # Dock: ensure System Settings (Ventura+) and System Preferences (legacy) are present
                dock.persistent-apps = [
                  "/System/Applications/System\ Settings.app/"
                  "/Applications/Google\ Chrome.app/"
                  "/Applications/Ghostty.app/"
                  "${pkgs.vscode}/Applications/Visual Studio Code.app"
                  "${pkgs.slack}/Applications/Slack.app"
                ];

                NSGlobalDomain.AppleInterfaceStyle = "Dark";
              };

              # Activation script: write VS Code settings (backs up existing)
              system.activationScripts.vscodeSettings = pkgs.lib.mkForce ''
                home="/Users/david"
                echo "writing VS Code settings to $${home}/Library/Application Support/Code/User/settings.json" >&2
                mkdir -p "$${home}/Library/Application Support/Code/User"
                if [ -f "$${home}/Library/Application Support/Code/User/settings.json" ]; then
                  cp -a "$${home}/Library/Application Support/Code/User/settings.json" "$${home}/Library/Application Support/Code/User/settings.json.nixbak-$(date +%s)" 2>/dev/null || true
                fi
                # Use the local installer script to write the full settings.json
                # This keeps the large JSONC out of the flake file while still
                # providing a reproducible activation step.

                # Prefer the repo-local settings.json if present
                SRC="$HOME/.config/vscode/settings.json"
                if [ -f "$SRC" ]; then
                  echo "copying $SRC to $${home}/Library/Application Support/Code/User/settings.json" >&2
                  cp -a "$SRC" "$${home}/Library/Application Support/Code/User/settings.json"
                else
                  echo "source settings not found: $SRC; skipping" >&2
                fi
                chown david:staff "$${home}/Library/Application Support/Code/User/settings.json" || true
              '';

              # Enable zsh and write a small .zshrc
              programs.zsh.enable = true;
              system.activationScripts.zshrc = pkgs.lib.mkForce ''
                              home="/Users/david"
                              mkdir -p $${home}
                              cat > $${home}/.zshrc <<'EOF'
                # Generated .zshrc
                export PATH=$PATH:~/.zig
                EOF
                              chown david:staff $${home}/.zshrc || true
              '';

              # Apply Home Manager for the primary user during darwin activation.
              # Instead of importing the NixOS-only Home Manager module (which
              # expects `utils` and `systemd`), we invoke the home-manager
              # binary as the user so the `homeConfigurations.david` in this
              # flake is applied.
              system.activationScripts.applyHomeManager = pkgs.lib.mkForce ''
                home="/Users/david"
                echo "applying home-manager for $${home}" >&2
                HM_BIN=""
                if [ -x "$${home}/.nix-profile/bin/home-manager" ]; then
                  HM_BIN="$${home}/.nix-profile/bin/home-manager"
                elif [ -x "/nix/var/nix/profiles/per-user/david/profile/bin/home-manager" ]; then
                  HM_BIN="/nix/var/nix/profiles/per-user/david/profile/bin/home-manager"
                elif command -v home-manager >/dev/null 2>&1; then
                  HM_BIN="$(command -v home-manager)"
                fi
                if [ -n "$HM_BIN" ] && [ -x "$HM_BIN" ]; then
                  # Run the switch as the user so files and profiles are created
                  su - david -c "HOME=$${home} $HM_BIN switch --flake /Users/david/.config#david" || true
                else
                  echo "home-manager binary not found; skipping" >&2
                fi
              '';
            }
          )
        ];
      };

      # Provide a home-manager configuration so you can switch user config
      homeConfigurations = {
        david = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          modules = [
            (
              { pkgs, ... }:
              {
                home.username = "david";
                home.homeDirectory = "/Users/david";

                programs.git = {
                  enable = true;
                  lfs.enable = true;
                  user.name = "david";
                  user.email = "davidblancoferrandez@gmail.com";
                  init.defaultBranch = "main";
                  pull.rebase = true;
                };

                # Example: ensure VS Code settings directory exists (activation handled by darwin)
                home.packages = [ pkgs.vscode ];
              }
            )
          ];
        };
      };
    };
}
