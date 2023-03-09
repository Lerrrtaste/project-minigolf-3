{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let
  devPythonVersion = "python3";

  # Allows reproducible python environments
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix";
    ref = "refs/tags/3.5.0";
  }) {
    # pypiDataRev = "982b6cdf6552fb9296e1ade29cf65a2818cbbd6b";
    # pypiDataSha256 = "166y0li0namv6a8ik8qq79ibck4w74x0wgypn9r7sqbb2wvcvcf3";
  };

  # Build python env from requirements.txt
  devPython = mach-nix.mkPython {
    python = devPythonVersion;
    requirements = ''
      gdtoolkit==4.*
    '';

    # avoid file collision with djangorestframework-jwt
    # _.djangorestframework-jwt-custom-user.postInstall = ''
    #   rm $out/lib/python3.8/site-packages/rest_framework_jwt/* -r
    # '';
  };
  # pypkgs = pkgs.python3.pkgs;

in mkShell {
  buildInputs = [
    (pkgs.callPackage ./godot4.nix { })
  ];
}
