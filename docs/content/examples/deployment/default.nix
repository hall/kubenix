{kubenix ? import ../../../..}:
kubenix.evalModules.${builtins.currentSystem} {
  module = {kubenix, ...}: {
    # instead of defining everything inline, let's import it
    imports = [./module.nix];

    # annotate the generated resources with a project name
    kubenix.project = "example";
    # define a target api version to validate output
    kubernetes.version = "1.24";
  };
}
