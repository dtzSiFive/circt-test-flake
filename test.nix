{ lib, runCommand
, circt, firrtl-src }:

let
  runOnInputs = circt: input_dir:
    runCommand "test-outputs" { nativeBuildInputs = [ (lib.getBin circt) ]; } ''
      firtool --version

      mkdir -p $out
      for x in ${input_dir}/*.fir; do
        BASE="$(basename $x)"
        OUT="$out/$BASE"
        \time -v firtool "$x" -o "$OUT.sv" |& tee "$OUT.log"
      done
    '';
  inputs = "${firrtl-src}/regress";
in
   runOnInputs circt.circt inputs
