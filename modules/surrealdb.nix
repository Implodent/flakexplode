let
  mapNullable = opt: mapper: if opt != null then (if builtins.isFunction mapper then mapper opt else mapper) else "";
  mapBind = bind: if builtins.isString bind then bind else "${bind.hostname}:${bind.port}";
  mapAuth = auth: "--auth --user ${auth.username} --pass ${auth.password}";
in
{
  perSystem = { config, lib, pkgs, system, ... }: with lib; {
    options.surrealdb = mkOption {
      description = mdDoc ''
        A SurrealDB flake-parts module, allowing declarative configuration of SurrealDB and ease of use of the configured executable.
      '';

      type = types.submodule {
        package = mkOption {
          type = types.package;
          default = inputs.surrealdb.packages.${system} ? pkgs.surrealdb;
          description = mdDoc ''
            The SurrealDB package to use.
          '';
        };
        wrapper = mkOption {
          type = types.package;
          description = mdDoc ''
            The SurrealDB package, wrapped with the config options.
          '';
          default = pkgs.writeShellScriptBin "surreal-start" ''
            exec ${config.package}/bin/surreal start ${mapNullable config.options.strict "--strict"}${mapNullable config.options.bind mapBind}${mapNullable config.options.auth mapAuth}{mapNullable config.options.logLevel (level: "--log ${level}")}${config.storage}
          '';
        };
        options = {
          storage = mkOption {
            type = types.str;
            default = "memory";
            description = mdDoc ''
              Sets the database path used for storing data
              Can be one of memory, file:<path>, tikv:<addr>, file://<path>, tikv://<addr> 
            '';
          };
          strict = mkOption {
            type = types.bool;
            default = false;
            description = mdDoc ''
              Enable [strict mode](https://surrealdb.com/docs/guides/strict-mode) for this SurrealDB instance.
            '';
          };
          bind = mkOption {
            type = types.either (types.str) types.submodule {
              hostname = mkOption {
                type = types.str;
                default = "0.0.0.0";
                description = mdDoc ''
                  The hostname to listen for connection on.
                '';
              };
              port = mkOption {
                type = types.port;
                default = 8000;
                description = mdDoc ''
                  The port to listen for connection on.
                '';
              };
            };
            description = mdDoc ''
              The hostname or IP address to listen for connections on.
            '';
          };
          logLevel = mkOption {
            default = "info";
            type = types.enum [ "error" "warn" "info" "debug" "trace" "full" ];
            example = "debug";
            description = mdDoc ''
              The logging level for the database server.
            '';
          };
          auth = mkOption {
            default = null;
            type = types.submodule {
              user = mkOption {
                type = types.str;
                description = mdDoc ''
                  The master username for the database. Usually `root`.
                '';
                example = "root";
              };
              password = mkOption {
                type = types.nullOr types.str;
                description = mdDoc ''
                  The master password for the database.
                '';
              };
            };
            description = mdDoc ''
              Configure authentication for this SurrealDB instance.
              NOTE: It is strongly recommended to enable auth mode (set auth to something non-null) when deploying SurrealDB in production. Not having it enabled can result in unauthorised access to your database.
            '';
          };
        };
      };
    };
  };
}
