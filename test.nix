{ lib, runCommand, linkFarm
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
      diffoscope --no-default-limits "${a}" "${b}" --html-dir $out || (echo "Files are different, expected.")
    '';
in
rec {
  normal = runOnInputs circt.circt inputs;
  pp = runOnInputs circt.circt-pp inputs;
  diff = diffEach normal pp;

  join = linkFarm "together" [
    { name = "normal"; path = normal; }
    { name = "pp"; path = pp; }
    { name = "diff"; path = diff; }
    ];
}
