{
  description = "Flake for rift-wm with automatic building of the latest stable version";

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixpkgs-unstable";
    };
  };

  outputs = {nixpkgs, ...}: let
    systems = ["aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: {
      default =
        nixpkgs.legacyPackages.${system}.callPackage ./rift.nix {};
    });

    overlays.default = final: _: {
      rift = final.callPackage ./rift.nix {};
    };
  };
}
