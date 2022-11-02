{ runCommand, circt-nix, firrtl-src }:

let
  runOnInputs = firtool: input_dir:
    runCommand "test-outputs" { } ''
    '';
  inputs = "${firrtl-src}/regress";
in
   runOnInputs circt-nix.circt inputs
