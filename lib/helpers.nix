{
  inputs,
  outputs,
  # stateVersion,
  ...
}:
{
  mkDarwin =
    {
      hostname,
      username ? "david",
      system ? "aarch64-darwin",
    }:
    let
      inherit (inputs.nixpkgs) lib;
    in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {
        inherit
          system
          inputs
          username
          ;
      };
      #extraSpecialArgs = { inherit inputs; }
      modules = [
        ../hosts/david
        inputs.home-manager.darwinModules.home-manager
        {
          networking.hostName = hostname;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.${username} = {
            imports = [ ./../home/${username}.nix ];
          };
        }
        inputs.nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            autoMigrate = true;
            mutableTaps = true;
            user = "${username}";
            taps = with inputs; {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
            };
          };
        }

      ];
    };
}
