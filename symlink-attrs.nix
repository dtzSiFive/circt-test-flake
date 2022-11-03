{ runCommand, lib, attrs, name }:
 
runCommand name { preferLocalBuild = true; allowSubstitutes = false; } (''
    mkdir -p $out
'' + lib.concatStrings (lib.mapAttrsToList (name: path: ''
    ln -s ${path} $out/${name}
'') attrs))
