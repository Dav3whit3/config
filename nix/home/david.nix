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
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  home.stateVersion = "25.05";

  # list of programs
  # https://mipmip.github.io/home-manager-option-search

  programs.gpg.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = false;
    initContent = (builtins.readFile ../data/mac-dot-zshrc);
  };

  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.nushell = {
    enable = true;
  };
  programs.zsh.shellAliases.nu = "nu --config ${config.home.homeDirectory}/.config/nushell/config.nu";

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--color=auto"
    ];
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        email = "davidblancoferrandez@gmail.com";
        name = "david";
      };
      init = {
        defaultBranch = "main";
      };
      merge = {
        conflictStyle = "diff3";
        tool = "code";
      };
      pull = {
        rebase = true;
      };
    };
  };

  programs.htop = {
    enable = true;
    settings.show_program_path = true;
  };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = pkgs.lib.importJSON ../../home/oh-my-posh/config.json;
  };

  programs.bash.enable = true;

  programs.home-manager.enable = true;
  programs.nix-index.enable = true;

  programs.bat = {
    enable = true;
    # config.theme = "Nord";
  };

  programs.zsh.shellAliases.cat = "${pkgs.bat}/bin/bat";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      StrictHostKeyChecking no
    '';
    matchBlocks = {

      "*" = {
        user = "root";
        extraOptions = {
          UserKnownHostsFile = "/dev/null";
          LogLevel = "ERROR";
        };
      };
      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
      };
    };
  };
}
