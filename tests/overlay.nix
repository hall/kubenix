{ pkgs
, overlay
, ...
}:
let
  inherit (pkgs) lib;

  marker = "sees-extended-package-set";

  overlaid = pkgs.extend (
    lib.composeExtensions overlay (_final: _prev: { kubenixOverlayMarker = marker; })
  );

  assertions = [
    {
      message = "the overlay provides pkgs.kubenix.evalModules";
      assertion = (overlaid ? kubenix) && builtins.isFunction overlaid.kubenix.evalModules;
    }
    {
      message = "the overlay's evalModules evaluates modules against the extended package set";
      assertion = (overlaid.kubenix.evalModules {
        module = { pkgs, lib, ... }: {
          options.marker = lib.mkOption { default = pkgs.kubenixOverlayMarker or null; };
        };
      }).config.marker == marker;
    }
  ];

  failures = map (a: a.message) (builtins.filter (a: !a.assertion) assertions);
in
pkgs.runCommand "kubenix-overlay" { } (
  if failures == [ ]
  then "echo success > $out"
  else "echo ${lib.escapeShellArg (builtins.concatStringsSep "\n" failures)} >&2; exit 1"
)
