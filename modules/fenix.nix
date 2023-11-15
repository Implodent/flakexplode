{
  perSystem = { config, lib, pkgs, system, inputs, ... }:
  let
        fenix = inputs.fenix.packages.${system};
        cfg = config.fenix;
  in with lib;
    {
      options.fenix = mkOption {
        type = types.submodule {
          enable = mkOption {
            types = types.bool;
            default = false;
            description = mdDoc "Enable this module.";
          };

          profile = mkOption {
            type = types.nullOr (types.enum [
              "minimal"
              "default"
              "complete"
              "latest"
            ]);
            default = null;
            description = mdDoc ''
              The profile that the Fenix toolchain will be constructed with.

              Can be: "minimal", "default", "complete", or "latest" (available on nightly channel only, pulls in all the components from "complete", but does not guarantee they are from the same date).
            '';
          };

          channel = mkOption {
            type = types.nullOr (types.enum [ "stable" "beta" "nightly" ]);
            default = null;
            description = mdDoc ''
              The channel that the Fenix toolchain will be constructed from.

              This is either "stable", "beta", or "nightly".
            '';
          };

          components = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = mdDoc ''
              The components that the resulting toolchain will contain.
            '';
          };

          target = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = mdDoc ''
              The target that the Rust toolchain will be built for.
            '';
          };

          precise = mkOption {
            type = types.nullOr (types.submodule {
              root = mkOption {
                type = types.str;
                default = "https://static.rust-lang.org/dist";
                description = mdDoc ''
                  The root URL for downloading the manifest.
                  Usually left as default.
                '';
              };
              channel = mkOption {
                type = types.str;
                default = "nightly";
                description = mdDoc ''
                  The Rust channel.
                  One of "stable", "beta", or "nightly". Can also be a version number.
                '';
              };
              date = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = mdDoc ''
                  The date of the toolchain, latest if null.
                '';
              };
              sha256 = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = mdDoc ''
                  sha256 of the manifest, required in pure evaluation mode, set to lib.fakeSha256 to get the actual sha256 from the error message
                '';
              };
            });
            default = null;
            description = mdDoc ''
              This option lets you pin the version of the toolchain to a specific channel, version number, or date.
            '';
          };

          manifest = mkOption {
            type = types.nullOr
              (types.either types.path (types.attrsOf types.anything));
            default = null;
            description = mdDoc ''
              The rust-toolchain file that the resulting toolchain will be constructed from.
            '';
          };

          toolchain = mkOption {
            type = types.attrsOf types.derivation;
            description = mdDoc ''
              The resulting Fenix toolchain, configured with this module's options under `fenix`.
              This is not meant to be modified, rather used after configuring this module.
            '';
          };

          rust-analyzer = mkOption {
            type = types.derivation;
            readOnly = true;
            default = fenix.rust-analyzer;
            description = mdDoc "The latest, nightly, version of rust-analyzer.";
          };
        };
        description = mdDoc ''
          Configuration for Fenix, a tool for managing Rust toolchains declaratively.
          This module is meant for users who want to have one singular toolchain for the entire flake and use it everywhere.
        '';
      };

      config.fenix.toolchain = mkIf config.fenix.enable (let
        apply = chan: profile: components: target:
          let
            applied = (let
              applied =
                (if profile != null then chan."${profile}Toolchain" else chan);
            in if components != [ ] then
              applied.withComponents components
            else
              applied);
          in if target != null then applied.targets.${target} else applied;
      in if cfg.precise != null then
        fenix.toolchainOf cfg.precise
      else if cfg.manifest != null then
        (if builtins.isAttrset cfg.manifest then
          fenix.fromManifest cfg.manifest
        else
          fenix.fromManifestFile cfg.manifest)
      else if cfg.channel != null then
        apply fenix.${cfg.channel} cfg.profile cfg.components cfg.target
      else if cfg.profile != null then
        apply fenix.${cfg.profile} null cfg.components cfg.target
      else
        throw "no configuration specified");
    };
}
