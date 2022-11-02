{ lib, time, runCommand
, circt, firrtl-src }:

let
  runOnInputs = circt: input_dir:
    runCommand "test-outputs" { nativeBuildInputs = [ (lib.getBin circt) time ]; } ''
      firtool --version

      mkdir -p $out
      for x in ${input_dir}/*.fir; do
        BASE="$(basename $x .fir)"
        OUT="$out/$BASE"
        mkdir -p $"$OUT"
        \time -v firtool "$x" -o "$OUT/$BASE.sv" \
          -mlir-timing -verbose-pass-executions \
          |& tee "$OUT/$BASE.log"
      done
    '';
  inputs = "${firrtl-src}/regress";
in
   runOnInputs circt.circt inputs
