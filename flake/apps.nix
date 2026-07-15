{ self, ... }:
{
  perSystem = { pkgs, ... }: {
    apps = {
      docs = {
        type = "app";
        meta = {
          description = "Generate and build the Kubenix documentation site using Hugo";
        };
        program = (pkgs.writeShellScript "gen-docs" ''
          set -eo pipefail

          # generate json object of module options
          nix build '.#docs'

          # copy file to avoid symlink in resulting build artifacts
          cp -f ./result ./docs/data/options.json

          # remove all old module pages
          rm ./docs/content/modules/[!_]?*.md || true

          # create a page for each module in hugo
          for mod in ${builtins.toString (builtins.attrNames self.nixosModules.kubenix)}; do
            [[ $mod == "base" ]] && mod=kubenix
            [[ $mod == "k8s" ]] && mod=kubernetes
            echo "&nbsp; {{< options >}}" > ./docs/content/modules/$mod.md
          done

          # build the site
          cd docs && ${pkgs.hugo}/bin/hugo "$@"
        '').outPath;
      };

      generate = {
        type = "app";
        meta = {
          description = "Generate Nix modules from Kubernetes specifications and CRDs";
        };
        program = (pkgs.writeShellScript "gen-modules" ''
          set -eo pipefail
          dir=./modules/generated

          rm -rf $dir
          mkdir $dir
          nix build '.#generate-k8s'
          cp ./result/* $dir/

          rm result
        '').outPath;
      };
    };
  };
}
