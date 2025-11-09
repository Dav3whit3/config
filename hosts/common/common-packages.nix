{
  inputs,
  pkgs,
  unstablePkgs,
  ...
}:
let
  inherit (inputs) nixpkgs nixpkgs-unstable;
in
{
  nixpkgs.config.allowUnfree = true;
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
}
