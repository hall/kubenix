{
  stdenvNoCC,
  lib,
  kubernetes-helm,
  gawk,
  remarshal,
  jq,
}:
with lib;
  {
    # chart to template
    chart,
    # release name
    name,
    # namespace to install release into
    namespace ? null,
    # values to pass to chart
    values ? {},
    # kubernetes version to template chart for
    kubeVersion ? null,
  }: let
    valuesJsonFile = builtins.toFile "${name}-values.json" (builtins.toJSON values);
  in
    stdenvNoCC.mkDerivation {
      name = "${name}.json";
      buildCommand = ''
        # template helm file and write resources to yaml
        helm template "${name}" \
          ${optionalString (kubeVersion != null) "--api-versions ${kubeVersion}"} \
          ${optionalString (namespace != null) "--namespace ${namespace}"} \
          ${optionalString (values != {}) "-f ${valuesJsonFile}"} \
          ${chart} >resources.yaml

        # split multy yaml file into multiple files
        awk 'BEGIN{i=1}{line[i++]=$0}END{j=1;n=0; while (j<i) {if (line[j] ~ /^---/) n++; else print line[j] >>"resource-"n".yaml"; j++}}' resources.yaml

        # join multiple yaml files in jsonl file
        for file in ./resource-*.yaml
        do
          remarshal -i $file -if yaml -of json >>resources.jsonl
        done

        # convert jsonl file to json array, remove null values and write to $out
        cat resources.jsonl | jq -Scs 'walk(
          if type == "object" then
            with_entries(select(.value != null))
          elif type == "array" then
            map(select(. != null))
          else
            .
          end)' > $out
      '';
      nativeBuildInputs = [kubernetes-helm gawk remarshal jq];
    }
