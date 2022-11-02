{ lib, runCommand
, time, diffoscope
, circt, firrtl-src }:

let
  runOnInputs = c: input_dir:
    runCommand "test-outputs" { nativeBuildInputs = [ (lib.getBin c) time ]; } ''
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

  # TODO: control/other outputs, better interface.
  diffEach = a: b: 
    runCommand "diff-outputs" { nativeBuildInputs = [ diffoscope ]; } ''
      for x in ${a}/*; do
        d="$(basename "$x")"
        a_d="${a}/$d"
        b_d="${b}/$d"
        o_d="$out/$d"
        mkdir -p "$o_d"
        diffoscope --no-default-limits "$a_d/$d.sv" "$b_d/$d.sv" \
          --markdown "$o_d/$d.md" \
          --html "$o_d/$d.html"
      done
    '';
in
rec {
  normal = runOnInputs circt.circt inputs;
  pp = runOnInputs circt.circt-pp inputs;
  diff = diffEach normal pp;
}
