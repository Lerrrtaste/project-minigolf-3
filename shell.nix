{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let
  devPythonVersion = "python3";

  # Allows reproducible python environments
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix";
    # ref = "refs/tags/3.5.0";
    ref = "master";
  }) {
    pypiDataRev = "52e77dc0078960e9dda215535424c5d4385829ca";
    pypiDataSha256 = "167mhxa2nr9ap1b646s6cqpzinz50h4iliiyqchrraz7fqb0b0bd";
  };

  # Build python env from requirements.txt
  devPython = mach-nix.mkPython {
    python = devPythonVersion;
    requirements = ''
      gdtoolkit>=4.0.0
      setuptools
    '';

    # avoid file collision with djangorestframework-jwt
    # _.djangorestframework-jwt-custom-user.postInstall = ''
    #   rm $out/lib/python3.8/site-packages/rest_framework_jwt/* -r
    # '';
  };
  # pypkgs = pkgs.python3.pkgs;

in mkShell { buildInputs = [ (pkgs.callPackage ./godot4.nix { }) devPython ]; }
