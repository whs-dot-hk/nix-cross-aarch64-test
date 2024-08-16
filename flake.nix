{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";

  outputs = {
    flake-utils,
    nixpkgs,
    rust-overlay,
    self,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        crossSystem = "aarch64-linux";
        inherit system;
        overlays = [(import rust-overlay)];
      };
      rustPlatform = pkgs.makeRustPlatform {
        cargo = pkgs.rust-bin.stable.latest.minimal;
        rustc = pkgs.rust-bin.stable.latest.minimal;
      };
    in {
      packages.default = let
        test = rustPlatform.buildRustPackage {
          cargoHash = "sha256-Z5Z37/wwoZufEuwB8PVIJyIJr2bwo+xDVFkJl6n8nHg=";
          pname = "test";
          src = ./.;
          version = "1.0.0";
        };
      in
        with pkgs;
          dockerTools.buildImage {
            name = "test";
            tag = "nix";
            copyToRoot = buildEnv {
              name = "image-root";
              paths = [dockerTools.caCertificates test];
            };
          };
    });
}
