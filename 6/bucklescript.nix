{ stdenv, fetchgit, ninja, nodejs, ocamlPackages, python35 }:
let
  version = "6.2.0";
  ocamlver = "4.06.1";
  src = import ./src.nix { inherit fetchgit; };
  ocaml =  import ./ocaml.nix {
    inherit stdenv fetchgit;
  };
  oPkgs = ocamlPackages.overrideScope' (self: super: {
    inherit ocaml;
  });
in
stdenv.mkDerivation {
  name = "bucklescript-${version}";
  version = version;
  inherit src;
  BS_RELEASE_BUILD = "true";
  buildInputs = [ ocaml oPkgs.cppo oPkgs.camlp4 ninja nodejs python35 ];
  buildPhase = ''
    mkdir -p $out 
    cp -rf jscomp lib scripts vendor odoc_gen $out
    cp -r bsconfig.json package.json $out

    mkdir -p $out/native/${ocamlver}/bin
    for name in $(find ${ocaml}/bin -printf "%P\n");
    do
        ln -sf ${ocaml}/bin/$name $out/native/${ocamlver}/bin/$name
    done

    rm -f $out/vendor/ninja/snapshot/ninja.linux
    cp ${ninja}/bin/ninja $out/vendor/ninja/snapshot/ninja.linux 
    node $out/scripts/ninja.js config
    node $out/scripts/ninja.js build

    sed -i 's:./configure.py --bootstrap:python3.5 ./configure.py --bootstrap:' $out/scripts/install.js
  '';
  installPhase = ''
    node $out/scripts/install.js

    mkdir -p $out/bin
    ln -s $out/lib/bsb $out/bin/bsb
    ln -s $out/lib/bsc $out/bin/bsc
    ln -s $out/lib/bsrefmt $out/bin/bsrefmt
    # remove unnecessary binaries
    rm $out/lib/*.darwin
    rm $out/lib/*.win32
  '';
}
