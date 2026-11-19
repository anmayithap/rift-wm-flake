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

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    systems = ["aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.callPackage ./rift.nix {};
      rift-lua = nixpkgs.legacyPackages.${system}.callPackage ./rift-lua.nix {};
    });

    checks = forAllSystems (system: {
      build = self.packages.${system}.default;
      rift-lua = self.packages.${system}.rift-lua;
    });

    overlays.default = final: _: {
      rift = final.callPackage ./rift.nix {};
      rift-lua = final.callPackage ./rift-lua.nix {};
    };
  };
}
