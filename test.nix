{ lib, runCommand
, circt, firrtl-src }:

let
  runOnInputs = circt: input_dir:
    runCommand "test-outputs" { nativeBuildInputs = [ (lib.getBin circt) ]; } ''
firtool --version
exit 1
    '';
  inputs = "${firrtl-src}/regress";
in
   runOnInputs circt.circt inputs
