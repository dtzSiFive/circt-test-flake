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
         in {
         packages = rec {
           results = import ./test.nix {
             inherit circt firrtl-src;
             inherit (pkgs) lib time runCommand;
           };
          default = results.circt-pp; }; 
       });

#        let pkgs = nixpkgs.legacyPackages.${system};
#            newLLVMPkgs = pkgs.callPackage ./llvm.nix {
#              inherit llvm-submodule-src;
#              llvmPackages = pkgs.llvmPackages_git;
#            };
#        in rec {
#          devShells = {
#            default = import ./shell.nix { inherit pkgs; };
#            git = import ./shell.nix {
#               inherit pkgs;
#               llvmPkgs = pkgs.llvmPackages_git; # NOT same as submodule.
#            };
#          };
#          packages = flake-utils.lib.flattenTree (newLLVMPkgs // rec {
#            default = circt; # default for `nix build` etc.
#
#            circt = pkgs.callPackage ./circt.nix {
#              inherit circt-src;
#              inherit (newLLVMPkgs) libllvm mlir llvmUtilsSrc;
#            };
#            circt-pp = circt.override { circt-src = circt-pp-src; };
#            slang = pkgs.callPackage ./slang.nix {
#              inherit slang-src;
#            };
#          });
#          apps = pkgs.lib.genAttrs [ "firtool" "circt-lsp-server" ]
#            (name: flake-utils.lib.mkApp { drv = packages.circt; inherit name; });
#        }
#      );

  nixConfig = {
    extra-substituters = [ "https://dtz-circt.cachix.org" ];
    extra-trusted-public-keys = [ "dtz-circt.cachix.org-1:PHe0okMASm5d9SD+UE0I0wptCy58IK8uNF9P3K7f+IU=" ];
  };
}
