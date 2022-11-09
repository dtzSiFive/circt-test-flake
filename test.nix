{ lib, runCommand, symlinkJoin, linkFarm
, time, diffoscope
, circt, firrtl-src, circt-perf-src }:

let
  symlink_attrs = name: attrs: import ./symlink-attrs.nix {
    inherit name attrs;
   inherit runCommand lib;
  };
 
  runOnInputs = name: c: input_dir:
    runCommand "test-outputs-${name}" { nativeBuildInputs = [ (lib.getBin c) time ]; } ''
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
  diffEach = lib.makeOverridable({
    name , a , b,
    withHTML ? true, withDiff ? true, withMD ? false,
    maxPageDiffBlockLines ? 100000
    } @diffargs:
    let
      diffoscopeCmd = [ "diffoscope" "--no-default-limits" "--max-page-diff-block-lines=${toString maxPageDiffBlockLines}" ];
      diff = a: b: outbase:
        toString (diffoscopeCmd ++ [ a b ]
        ++ lib.optional withHTML "--html=${outbase}.html"
        ++ lib.optional withDiff "--text=${outbase}.diff"
        ++ lib.optional withMD "--md=${outbase}.md"
        ++ [ '' || (echo "Files ${a} and ${b} are different, see output files (${outbase}*) for details") '']);
     linkResult = { base,  name, ext }: ''[<a href="${base}.${ext}">${name}</a>] '';
     genHTMLLine = results: lib.concatMapStrings linkResult results;
     resultsForOutputs = { base, html ? withHTML, diff ? withDiff, md ? withMD, namePrefix ? "" }:
       []
       ++ lib.optional html { inherit base; name = "${namePrefix}HTML"; ext = "html"; }
       ++ lib.optional diff { inherit base; name = "${namePrefix}Diff (raw)"; ext = "diff"; }
       ++ lib.optional md { inherit base; name = "${namePrefix}MD"; ext = "md"; };
     results =
       (resultsForOutputs {base="$d/$d";}) ++
       (resultsForOutputs {base="$d/$d-log"; md = false; namePrefix = "Log "; });
     htmlLine = genHTMLLine results;
    in
    runCommand "diff-outputs-${name}" { nativeBuildInputs = [ diffoscope ]; } ''
      for x in ${a}/*; do
        d="$(basename "$x")"
        a_d="${a}/$d"
        b_d="${b}/$d"
        o_d="$out/$d"

        mkdir -p "$o_d"
        ${diff "$a_d/$d.sv" "$b_d/$d.sv" "$out/$d/$d"}
        ${diff "$a_d/$d.log" "$b_d/$d.log" "$out/$d/$d-log"}
        echo "$d: ${htmlLine} <br>" >> $out/index.html
      done
    '');

  # Gather inputs.
  firrtl-inputs = "${firrtl-src}/regress";
  circt-perf-inputs = lib.sourceByRegex "${circt-perf-src}/regress" [
   ''test.*\.fir''
   ''chipyard.*\.hi\.fir''
  ];
  # inputs = symlinkJoin { name = "inputs"; paths = [ firrtl-inputs circt-perf-inputs ]; };
  mkResultSetFor = { name, inputs, ...} @ args: rec {
    normal = runOnInputs "normal" circt.circt inputs;
    pp = runOnInputs "pp" circt.circt-pp inputs;
    diff = diffEach ({ a = normal; b = pp; } // (builtins.removeAttrs args [ "inputs" ]));
  };
  results = {
    firrtl-regress = mkResultSetFor { name = "firrtl-regress"; inputs = firrtl-inputs; };
    circt-perf-examples = mkResultSetFor {
      name = "circt-perf-examples";
      inputs = circt-perf-inputs;
      withHTML = false; # too big
    };
  };
  linkedResults = lib.mapAttrs (n: p: symlink_attrs n p) results;
  combined = attrs: runCommand "combine" { preferLocalBuild = true; } (''
    mkdir -p $out
  '' + lib.concatStrings (lib.mapAttrsToList (name: path: ''
    ln -s ${path}/diff/*/ $out/
    cat ${path}/diff/index.html >> $out/index.html
  '') attrs));
in {
  join = combined linkedResults;
}
#    name = "normal"; path = linkFarm 
#  ];
#  normal = runOnInputs "normal" circt.circt inputs;
#  pp = runOnInputs "pp" circt.circt-pp inputs;
#  diff = diffEach normal pp;
#
#  join = linkFarm "together" [
#    { name = "normal"; path = normal; }
#    { name = "pp"; path = pp; }
#    { name = "diff"; path = diff; }
#    ];
#}
