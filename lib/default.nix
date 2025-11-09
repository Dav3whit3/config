{
  inputs,
  outputs,
  # stateVersion,
  ...
}:
let
  helpers = import ./helpers.nix { inherit inputs outputs; };
in
{
  inherit (helpers)
    mkDarwin
    ;
}
