{ lib, runCommand, symlinkJoin, linkFarm
, time, diffoscope
, circt, firrtl-src, circt-perf-src }:

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
          --max-page-diff-block-lines 100000 \
          --html "$o_d/$d.html" \
          --text "$o_d/$d.diff" \
          || (echo "Files are different, see output files for details")
        diffoscope --no-default-limits "$a_d/$d.log" "$b_d/$d.log" \
          --max-page-diff-block-lines 100000 \
          --html "$o_d/$d-log.html" \
          --text "$o_d/$d-log.diff" \
          || (echo "Files are different, see output files for details")
        echo "$d: <a href=\"$d/$d.html\">HTML</a> <a href=\"$d/$d.diff\">.diff</a> <a href=\"$d/$d-log.html\">(log diff)</a><br>" >> $out/index.html
      done
    '';

  # Gather inputs.
  firrtl-inputs = "${firrtl-src}/regress";
  circt-perf-inputs = lib.sourceByRegex "${circt-perf-src}/regress" [
   ''test.*\.fir''
   ''chipyard.*\.hi\.fir''
  ];
  inputs = symlinkJoin { name = "inputs"; paths = [ firrtl-inputs circt-perf-inputs ]; };
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
