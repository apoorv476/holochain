# Definitions can be imported from a separate file like this one

{ self, inputs, lib, ... }@flake: {
  perSystem = { config, self', inputs', system, pkgs, ... }:
    let

      rustToolchain = config.rust.mkRust {
        track = "stable";
        version = "1.66.1";
      };
      craneLib = inputs.crane.lib.${system}.overrideToolchain rustToolchain;

      commonArgs = {

        pname = "hc-scaffold";
        src = inputs.scaffolding;

        CARGO_PROFILE = "release";

        cargoExtraArgs = "--bin hc-scaffold";

        buildInputs =
          (with pkgs; [
            openssl

            # TODO: remove sqlite package once https://github.com/holochain/holochain/pull/2248 is released
            sqlite
          ])
          ++ (lib.optionals pkgs.stdenv.isDarwin
            (with pkgs.darwin.apple_sdk_11_0.frameworks; [
              AppKit
              CoreFoundation
              CoreServices
              Security
            ])
          )
          # ++ self'.packages.holochain.buildInputs
        ;

        nativeBuildInputs =
          (with pkgs; [
            perl
            pkg-config
            makeBinaryWrapper
            go
          ])
          ++ lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
            xcbuild
            libiconv
          ])
          # ++ self'.packages.holochain.nativeBuildInputs
        ;

        doCheck = false;
      };

      # derivation building all dependencies
      deps = craneLib.buildDepsOnly (commonArgs // { });

      # derivation with the main crates
      package = craneLib.buildPackage (commonArgs // {
        cargoArtifacts = deps;

        preFixup = ''
          wrapProgram $out/bin/hc-scaffold \
            --prefix PATH : ${rustToolchain}/bin
        '';
      });

    in
    {
      packages = {
        hc-scaffold = package;
      };
    };
}
