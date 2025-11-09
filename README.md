# personal nix-darwin configuration

This repository contains a single-file flake at `flake.nix` that defines a
nix-darwin configuration for host `david` and also exposes a Home Manager
user configuration `homeConfigurations.david`.

Quick summary

- System config: `darwinConfigurations.david`
- Home config: `homeConfigurations.david`
- Activation logs: `/var/log/darwin-activation.log`

Files of note

- `flake.nix` - single-file flake with nix-darwin + Home Manager (darwin-native activation)
- `scripts/bootstrap-home-manager.sh` - one-shot installer (per-user) to install `home-manager` into the user profile and run an initial switch
- `scripts/test-activation-dryrun.sh` - dry-run test that simulates activation scripts against a temporary home
- `Justfile` - task shortcuts (bootstrap, rebuild, dry-run, view logs)

Home Manager activation behavior

- The darwin activation now builds the flake's Home Manager activation package and runs it as the `david` user. This is implemented in `system.activationScripts.applyHomeManager` and uses `nix build "/Users/david/.config#homeConfigurations.david.activationPackage" -o /nix/var/nix/profiles/per-user/root/home-activation`.
- The activation step uses a persistent symlink under `/nix/var/nix/profiles/per-user/root/home-activation` so repeated activations can reuse the previously-built package when unchanged.

Bootstrapping

1. Optional: run the bootstrap script once as your normal user to install a per-user `home-manager` binary:

   chmod +x scripts/bootstrap-home-manager.sh
   ./scripts/bootstrap-home-manager.sh /Users/david/.config

2. Apply the system configuration with:

   sudo darwin-rebuild switch --flake /Users/david/.config#david

Logs

- Check `/var/log/darwin-activation.log` for timestamped messages written by the activation scripts (VS Code settings writer, .zshrc writer, home activation).

Dry-run testing

- Use the provided dry-run script to simulate what activation would do without touching your real home:

  ./scripts/test-activation-dryrun.sh

If you want any additional commands in the `Justfile` or a CI-friendly test harness, tell me which commands you'd like and I'll add them.
