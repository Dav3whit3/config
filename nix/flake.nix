/*
  Installation steps
  # https://www.youtube.com/watch?v=Z8BL8mdzWHI&ab_channel=DreamsofAutonomy

  1.- Install Nix
  sh <(curl -L https://nixos.org/nix/install)

  2.- Check Nix is working & install neofetch
  nix-shell -p neofetch --run neofetch

  3.- Install nix-darwin
  sudo -E nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/.config/nix#m2pro
  sudo darwin-rebuild switch --flake ~/.config/nix#m2pro
*/

{
  description = "Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {
          nixpkgs.config.allowUnfree = true;

          # Required by nix-darwin migration: options that previously applied to
          # the user running darwin-rebuild must now be tied to system.primaryUser.
          # Set this to the username that you use to run darwin-rebuild.
          system.primaryUser = "david";

          environment.systemPackages = [
            pkgs.mkalias
            pkgs.nixfmt
            pkgs.vscode
            pkgs.oh-my-posh
            pkgs.helix
            pkgs.lazygit
            pkgs.raycast
            pkgs.rectangle
            pkgs.ngrok
            pkgs.slack
            pkgs.htop
            pkgs.stats
            pkgs.uv
            pkgs.ruff
            pkgs.bat
            pkgs.colorls
            pkgs.amazon-q-cli
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
            };
            casks = [
              "ghostty"
            ];
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
          };

          services.postgresql.enable = true;
          services.postgresql.package = pkgs.postgresql_18;
          services.postgresql.initdbArgs = [
            "-D"
            "/var/lib/postgresql/18"
          ];
          services.postgresql.authentication = pkgs.lib.mkOverride 10 ''
            #type database  DBuser  auth-method
            local all       all     trust
            host  david    all     127.0.0.1/32 scram-sha-256
            host  david    all     ::1/128 scram-sha-256
          '';

          # Mac settings.
          system.defaults = {
            dock.persistent-apps = [
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

          # Mac Symlinks
          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              # Set up applications.
              echo "setting up /Applications..." >&2

              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |

              while IFS= read -r src; do
                app_name=$(basename "$src")
                echo "copying $src" >&2
                ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"

              done
            '';

          # Create or update the user's ~/.zshrc with curated content. This will
          # back up any existing file to ~/.zshrc.nixbak-<ts> and then write the
          # requested content. We write to /Users/<primaryUser> so activation
          # performed as root updates the correct home.
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

          # Create or update the user's VS Code settings.json under
          # ~/Library/Application Support/Code/User/settings.json. Back up any
          # existing file to settings.json.nixbak-<ts> and then write the
          # requested content. This runs during system activation so that
          # darwin-rebuild as root updates the correct home.
          system.activationScripts.vscodeSettings =
            let
              home = "/Users/${config.system.primaryUser}";
            in
            pkgs.lib.mkForce ''
                echo "writing VS Code settings to ${home}/Library/Application Support/Code/User/settings.json" >&2
                mkdir -p "${home}/Library/Application Support/Code/User"
                if [ -f "${home}/Library/Application Support/Code/User/settings.json" ]; then
                  cp -a "${home}/Library/Application Support/Code/User/settings.json" "${home}/Library/Application Support/Code/User/settings.json.nixbak-$(date +%s)" 2>/dev/null || true
                fi
                cat > "${home}/Library/Application Support/Code/User/settings.json" <<'EOF'
              {
                // Languages
                "[python]": {
                  "editor.formatOnSave": true,
                  "editor.codeActionsOnSave": {
                    "source.fixAll": "explicit",
                    "source.organizeImports": "explicit",
                    "source.showNotifications": "always"
                  }
                },
                "[html]": {
                  "editor.defaultFormatter": "esbenp.prettier-vscode"
                },
                "[javascript]": {
                  "editor.defaultFormatter": "esbenp.prettier-vscode"
                },
                "[typescript]": {
                  "editor.defaultFormatter": "esbenp.prettier-vscode"
                },
                "[css]": {
                  "editor.defaultFormatter": "esbenp.prettier-vscode"
                },

                "[json]": {
                  "editor.defaultFormatter": "esbenp.prettier-vscode"
                },

                // Vim
                "vim.normalModeKeyBindingsNonRecursive": [
                  {
                    "before": ["a"],
                    "commands": []
                  },
                  {
                    "before": ["s"],
                    "commands": []
                  },
                  {
                    "before": ["q"],
                    "commands": []
                  },
                  {
                    "before": ["d"],
                    "commands": []
                  },
                  {
                    "before": ["c"],
                    "commands": []
                  },
                  {
                    "before": ["r"],
                    "commands": []
                  },
                  {
                    "before": ["x"],
                    "commands": []
                  },
                  {
                    "before": ["u"],
                    "commands": []
                  },
                  {
                    "before": ["U"],
                    "commands": []
                  },
                  {
                    "before": ["o"],

                    "commands": []
                  },
                  {
                    "before": ["O"],
                    "commands": []
                  },
                  {
                    "before": ["p"],

                    "commands": []
                  },
                  {
                    "before": ["P"],
                    "commands": []
                  },
                  {
                    "before": ["A"],
                    "commands": []
                  },
                  {
                    "before": ["S"],
                    "commands": []
                  },
                  {
                    "before": ["Q"],
                    "commands": []
                  },
                  {
                    "before": ["D"],
                    "commands": []
                  },
                  {
                    "before": ["C"],
                    "commands": []
                  },
                  {
                    "before": ["R"],
                    "commands": []
                  },
                  {
                    "before": ["X"],
                    "commands": []
                  },
                  {
                    "before": ["´"],
                    "commands": []
                  },
                  {
                    "before": ["."],
                    "commands": []
                  },
                  {
                    "before": ["<"],
                    "commands": []
                  }
                ],

                // Python
                "python.languageServer": "Default",
                "python.analysis.typeCheckingMode": "basic",
                "python.envFile": "$${workspaceFolder}/api/.env",
                "python.analysis.extraPaths": ["$${workspaceFolder}/api"],

                "terminal.integrated.enableMultiLinePasteWarning": "never",
                "zenMode.hideLineNumbers": false,
                "zenMode.hideStatusBar": true,
                "zenMode.hideActivityBar": true,
                "security.workspace.trust.untrustedFiles": "open",
                "editor.suggest.preview": false,

                "files.exclude": {
                  "**/.ipynb_checkpoints": true,
                  "**/__pycache__": true
                },
                "editor.tokenColorCustomizations": {
                  "textMateRules": [
                    {
                      "scope": "meta.function-call",
                      "settings": {
                        "foreground": "#9ed8fa"
                      }
                    },
                    {
                      "scope": "constant",
                      "settings": {
                        "foreground": "#0099ff"
                      }
                    },
                    {
                      "scope": "storage.type.function",
                      "settings": {
                        "fontStyle": "italic underline"
                      }
                    },
                    {
                      "scope": "constant",
                      "settings": {
                        "foreground": "#0099ff"
                      }
                    },
                    {
                      "scope": "meta.function-call",
                      "settings": {
                        "foreground": "#9ed8fa"
                      }
                    },
                    {
                      "scope": "constant",
                      "settings": {
                        "foreground": "#0099ff"
                      }
                    },
                    {
                      "scope": "storage.type.function",
                      "settings": {
                        "fontStyle": "italic underline"
                      }
                    },
                    {
                      "scope": "constant",
                      "settings": {
                        "foreground": "#0099ff"
                      }
                    },
                    {
                      "scope": "meta.function-call",
                      "settings": {
                        "foreground": "#9ed8fa"
                      }
                    },
                    {
                      "scope": "constant",
                      "settings": {
                        "foreground": "#0099ff"
                      }
                    },
                    {
                      "scope": "storage.type.function",
                      "settings": {
                        "fontStyle": "italic underline"
                      }
                    },
                    {
                      "scope": "constant",
                      "settings": {
                        "foreground": "#0099ff"
                      }
                    },
                    {
                      "scope": "meta.function-call",
                      "settings": {
                        "foreground": "#9ed8fa"
                      }
                    },
                    {
                      "scope": "constant",
                      "settings": {
                        "foreground": "#0099ff"
                      }
                    },
                    {
                      "scope": "storage.type.function",
                      "settings": {
                        "fontStyle": "italic underline"
                      }
                    },
                    {
                      "scope": "constant",
                      "settings": {
                        "foreground": "#0099ff"
                      }
                    },
                    {
                      "scope": "meta.function-call",
                      "settings": {
                        "foreground": "#9ed8fa"
                      }
                    },
                    {
                      "scope": "constant",
                      "settings": {
                        "foreground": "#0099ff"
                      }
                    },
                    {
                      "scope": "storage.type.function",
                      "settings": {
                        "fontStyle": "italic underline"
                      }
                    },
                    {
                      "scope": "constant",
                      "settings": {
                        "foreground": "#0099ff"
                      }
                    }
                  ]
                },
                EOF

              chown ${config.system.primaryUser}:staff "${home}/Library/Application Support/Code/User/settings.json" || true
            '';

          # nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Create /etc/zshrc that loads the nix-darwin environment.
          programs.zsh.enable = true; # default shell on catalina
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .
      darwinConfigurations."m2pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = "david";
              autoMigrate = true;
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."m2pro".pkgs;
    };
}
