/*
  Installation steps
  # https://www.youtube.com/watch?v=Z8BL8mdzWHI&ab_channel=DreamsofAutonomy

  1.- Install Nix
  sh <(curl -L https://nixos.org/nix/install)

  2.- Check Nix is working & install neofetch
  nix-shell -p neofetch --run neofetch

  3.- Install nix-darwin
  sudo -E nix run nix-darwin -- switch --flake ~/.config#david
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

              # Enable nix CLI experimental features (flakes) and reduce noisy
              # repository dirty warnings for developer workflows.
              nix.settings = {
                experimental-features = [
                  "nix-command"
                  "flakes"
                ];
                warn-dirty = false;
              };

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
                just
                zoxide
              ];

              homebrew = {
                enable = true;
                brews = [
                  "neovim"
                  "docker"
                  "redis"
                  "postgresql@18"
                  "python@3.13"
                  "python@3.14"
                  "pyright"
                ];
                masApps = {
                  "Whatsapp" = 310633997;
                  "Bitwarden" = 1352778147;
                };
                casks = [
                  "ghostty"
                  "discord"
                ];
                onActivation.cleanup = "zap";
                onActivation.autoUpdate = true;
              };

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

                finder.FXPreferredViewStyle = "clmv";
                loginwindow.GuestEnabled = false;
                NSGlobalDomain.AppleInterfaceStyle = "Dark";
                NSGlobalDomain.KeyRepeat = 2;
              };

              system.defaults.CustomUserPreferences = {
                "com.apple.finder" = {
                  ShowExternalHardDrivesOnDesktop = true;
                  ShowHardDrivesOnDesktop = false;
                  ShowMountedServersOnDesktop = false;
                  ShowRemovableMediaOnDesktop = true;
                  _FXSortFoldersFirst = true;
                  # When performing a search, search the current folder by default
                  FXDefaultSearchScope = "SCcf";
                  DisableAllAnimations = true;
                  NewWindowTarget = "PfDe";
                  NewWindowTargetPath = "file://$\{HOME\}/Desktop/";
                  AppleShowAllExtensions = true;
                  FXEnableExtensionChangeWarning = false;
                  ShowStatusBar = true;
                  ShowPathbar = true;
                  WarnOnEmptyTrash = false;
                };
                "com.apple.dock" = {
                  autohide = true;
                  launchanim = false;
                  static-only = false;
                  show-recents = false;
                  show-process-indicators = true;
                  orientation = "left";
                  tilesize = 36;
                  minimize-to-application = true;
                  mineffect = "scale";
                  enable-window-tool = false;
                };
              };

              # Activation script: write VS Code settings (backs up existing)
              system.activationScripts.vscodeSettings = pkgs.lib.mkForce ''
                home="/Users/david"
                LOG="/var/log/darwin-activation.log"
                destDir="$${home}/Library/Application Support/Code/User"
                dest="$${destDir}/settings.json"
                tmp="$${dest}.tmp.$$"
                SRC="$HOME/.config/vscode/settings.json"
                mkdir -p "$${destDir}"
                echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - vscodeSettings: checking $SRC -> $dest" >> "$LOG" 2>/dev/null || true
                if [ -f "$SRC" ]; then
                  if [ -f "$dest" ] && cmp -s "$SRC" "$dest"; then
                    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - vscodeSettings: identical; skipping" >> "$LOG" 2>/dev/null || true
                  else
                    if [ -f "$dest" ]; then
                      cp -a "$dest" "$${dest}.nixbak-$(date +%s)" 2>/dev/null || true
                    fi
                    # copy atomically
                    cp -a "$SRC" "$tmp" && mv -f "$tmp" "$dest"
                    chown david:staff "$dest" || true
                    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - vscodeSettings: written $dest" >> "$LOG" 2>/dev/null || true
                  fi
                else
                  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - vscodeSettings: source not found: $SRC; skipping" >> "$LOG" 2>/dev/null || true
                fi
              '';

              system.activationScripts.zshrc =
                let
                  home = "/Users/${config.system.primaryUser}";
                in
                pkgs.lib.mkForce ''
                  echo "writing zshrc to ${home}/.zshrc" >&2

                  cat > ${home}/.zshrc <<'EOF'
                  # Amazon Q pre block. Keep at the top of this file.
                  [[ -f "$${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "$${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

                  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.json)"

                  # Add Zig programming language to PATH
                  export PATH=$PATH:~/.zig

                  # BAT
                  export BAT_THEME='gruvbox-dark'
                  alias cat="bat --paging=never"

                  # COLORLS
                  alias ls='colorls -lA --sd'

                  # Amazon Q post block. Keep at the bottom of this file.
                  [[ -f "$${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "$${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
                  EOF

                  chown ${config.system.primaryUser}:staff ${home}/.zshrc || true
                '';

              # Apply Home Manager for the primary user during darwin activation.
              # Instead of importing the NixOS-only Home Manager module (which
              # expects `utils` and `systemd`), we invoke the home-manager
              # binary as the user so the `homeConfigurations.david` in this
              # flake is applied.
              system.activationScripts.applyHomeManager = pkgs.lib.mkForce ''
                # Darwin-native Home Manager activation: build the flake's
                # homeConfigurations.david.activationPackage and run the
                # resulting activation as the user. This avoids depending on a
                # preinstalled user-level home-manager binary.
                FLAKE="/Users/david/.config"
                # Use a persistent output symlink so repeated activations can
                # reuse a previously-built activation package (acts as a cache).
                OUT="/nix/var/nix/profiles/per-user/root/home-activation"
                LOG="/var/log/darwin-activation.log"
                echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - home-activation: building activationPackage from /Users/david/.config#homeConfigurations.david" >> "$LOG" 2>/dev/null || true
                if command -v nix >/dev/null 2>&1; then
                  nix build "/Users/david/.config#homeConfigurations.david.activationPackage" -o "$OUT" >/dev/null 2>&1 || {
                    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - home-activation: build failed; skipping" >> "$LOG" 2>/dev/null || true
                    exit 0
                  }

                  ACT=""
                  if [ -x "$OUT/activate" ]; then
                    ACT="$OUT/activate"
                  elif [ -x "$OUT/bin/activate" ]; then
                    ACT="$OUT/bin/activate"
                  elif [ -x "$OUT/bin/home-manager-activate" ]; then
                    ACT="$OUT/bin/home-manager-activate"
                  fi

                  if [ -n "$ACT" ]; then
                    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - home-activation: running activation as user david" >> "$LOG" 2>/dev/null || true
                    sudo -u david -H -- env HOME=/Users/david "$ACT" || true
                    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - home-activation: finished" >> "$LOG" 2>/dev/null || true
                  else
                    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - home-activation: activation script not found in $OUT; skipping" >> "$LOG" 2>/dev/null || true
                  fi

                  # cleanup symlink created by nix build
                  rm -f "$OUT"
                else
                  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - home-activation: nix not available; skipping" >> "$LOG" 2>/dev/null || true
                fi
              '';

              # Schedule weekly garbage collection for Nix via launchd.
              # This creates /Library/LaunchDaemons/com.david.nix-collect-garbage.plist
              # and attempts to load it. Runs `nix-collect-garbage -d` every Monday at 03:00.
              system.activationScripts.nixGarbageCollect = pkgs.lib.mkForce ''
                  LOG="/var/log/darwin-activation.log"
                  PLIST_PATH="/Library/LaunchDaemons/com.david.nix-collect-garbage.plist"
                  TMP_PLIST="/tmp/com.david.nix-collect-garbage.plist.$$"
                  NIXCG="$(command -v nix-collect-garbage || true)"
                  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - nixGC: start" >> "$LOG" 2>/dev/null || true
                  if [ -z "$NIXCG" ]; then
                    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - nixGC: nix-collect-garbage not found; skipping" >> "$LOG" 2>/dev/null || true
                    exit 0
                  fi

                  cat > "$TMP_PLIST" <<EOF
                  <?xml version="1.0" encoding="UTF-8"?>
                  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                  <plist version="1.0">
                  <dict>
                    <key>Label</key>
                    <string>com.david.nix-collect-garbage</string>
                    <key>ProgramArguments</key>
                    <array>
                      <string>$NIXCG</string>
                      <string>-d</string>
                    </array>
                    <key>StartCalendarInterval</key>
                    <dict>
                      <key>Weekday</key>
                      <integer>1</integer>
                      <key>Hour</key>
                      <integer>3</integer>
                      <key>Minute</key>
                      <integer>0</integer>
                    </dict>
                    <key>StandardOutPath</key>
                    <string>/var/log/nix-gc.log</string>
                    <key>StandardErrorPath</key>
                    <string>/var/log/nix-gc.log</string>
                  </dict>
                  </plist>
                  EOF

                # Atomically install the plist, set ownership and permissions
                mv -f "$TMP_PLIST" "$PLIST_PATH"
                chown root:wheel "$PLIST_PATH" || true
                chmod 644 "$PLIST_PATH" || true

                # Reload via launchctl: unload then load (safe idempotent)
                launchctl bootout system "$PLIST_PATH" >/dev/null 2>&1 || true
                launchctl bootstrap system "$PLIST_PATH" >/dev/null 2>&1 || true
                echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - nixGC: installed $PLIST_PATH" >> "$LOG" 2>/dev/null || true
              '';
            }
          )
        ];
      };

      # Provide a home-manager configuration so you can switch user config
      homeConfigurations = {
        david = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          # Enable zsh and write a small .zshrc
          programs.bash.enable = true;
          programs.zsh.enable = true;
          programs.home-manager.enable = true;
          programs.bat.enable = true;

          programs.git = {
            enable = true;
            lfs.enable = true;
            user.name = "david";
            user.email = "davidblancoferrandez@gmail.com";
            init.defaultBranch = "main";
            pull.rebase = true;
          };

          programs.oh-my-posh = {
            enable = true;
            enableZshIntegration = true;
            enableBashIntegration = true;
            settings = pkgs.lib.importTOML ./oh-my-posh/config.json;
          };
          modules = [
            (
              { pkgs, ... }:
              {
                home.username = "david";
                home.homeDirectory = "/Users/david";

                # Example: ensure VS Code settings directory exists (activation handled by darwin)
                home.packages = [ pkgs.vscode ];
              }
            )
          ];
        };
      };
    };
}
