{
  description = "Run CIRCT on FIRRTL regression files";


  inputs = {
    circt-nix.url = "github:dtzSiFive/circt-nix";
    firrtl-src.url = "github:chipsalliance/firrtl";
    firrtl-src.flake = false;

    flake-utils.url = "github:numtide/flake-utils";
    # From README.md: https://github.com/edolstra/flake-compat
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
  };

  outputs = { self
    , circt-nix
    , nixpkgs
    , flake-compat, flake-utils
    , firrtl-src
    }: flake-utils.lib.eachDefaultSystem
      (system: let
         pkgs = nixpkgs.legacyPackages.${system};
         circt = circt-nix.packages.${system};
         results = import ./test.nix {
           inherit circt firrtl-src;
           inherit (pkgs) lib time runCommand linkFarm;
           diffoscope = pkgs.diffoscopeMinimal;
         };
         in {
           packages = results // {
            default = results.join;
           };
         });

  nixConfig = {
    extra-substituters = [ "https://dtz-circt.cachix.org" ];
    extra-trusted-public-keys = [ "dtz-circt.cachix.org-1:PHe0okMASm5d9SD+UE0I0wptCy58IK8uNF9P3K7f+IU=" ];
  };
}
