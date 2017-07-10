{ mkDerivation, base, stdenv }:
mkDerivation {
  pname = "thm33";
  version = "0.1.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base ];
  homepage = "https://github.com/akc/thm33";
  description = "CLI to Theorem 3.3 of Guibas and Odlyzko - String overlaps ...";
  license = stdenv.lib.licenses.bsd3;
}
