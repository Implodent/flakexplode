{
  description = "FlakeXplode - flake-parts modules for SurrealDB & fenix";

  outputs = { self }:
    rec {
      flakeModules = {
        default = { imports = [ flakeModules.surrealdb flakeModules.fenix ]; };
        surrealdb = import ./modules/surrealdb.nix;
        fenix = import ./modules/fenix.nix;
      };
      flakeModule = flakeModules.default;
    };
}
