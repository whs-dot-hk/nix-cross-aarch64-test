{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";

  inputs.zksync-era.url = "github:matter-labs/zksync-era/core-v24.9.0";

  inputs.zksync-era.flake = false;

  outputs = {
    flake-utils,
    nixpkgs,
    rust-overlay,
    self,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
      };
      rustPlatform = pkgs.makeRustPlatform {
        cargo = pkgs.rust-bin.fromRustupToolchainFile (inputs.zksync-era + /rust-toolchain);
        rustc = pkgs.rust-bin.fromRustupToolchainFile (inputs.zksync-era + /rust-toolchain);
      };
    in {
      packages.default = let
        test = rustPlatform.buildRustPackage.override {stdenv = pkgs.clangStdenv;} {
          buildInputs = [pkgs.openssl];
          cargoBuildFlags = "--bin zksync_external_node";
          cargoHash = "sha256-7CO48+RFqlhm+/6QVNyX8059orU9DhrzLbZyEA/M0hg=";
          doCheck = false;
          nativeBuildInputs = [pkgs.pkg-config pkgs.rustPlatform.bindgenHook];
          pname = "test";
          src = inputs.zksync-era + /.;
          version = "1.0.1";
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
