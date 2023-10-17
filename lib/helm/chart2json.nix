{ runCommand, lib, kubernetes-helm, yq }:
with lib;
{
  # chart to template
  chart
  # release name
, name
  # namespace to install release into
, namespace ? null
  # values to pass to chart
, values ? { }
  # kubernetes version to template chart for
, kubeVersion ? null
  # whether to include CRD
, includeCRDs ? false
  # whether to include hooks
, noHooks ? false
  # Kubernetes api versions used for Capabilities.APIVersions (--api-versions)
, apiVersions ? null
}:
let
  valuesJsonFile = builtins.toFile "${name}-values.json" (builtins.toJSON values);
  # The `helm template` and YAML -> JSON steps are separate `runCommand` derivations for easier debuggability
  resourcesYaml = runCommand "${name}.yaml" { nativeBuildInputs = [ kubernetes-helm ]; } ''
    helm template "${name}" \
        ${optionalString (apiVersions != null && apiVersions != []) "--api-versions ${lib.strings.concatStringsSep "," apiVersions}"} \
        ${optionalString (kubeVersion != null) "--kube-version ${kubeVersion}"} \
        ${optionalString (namespace != null) "--namespace ${namespace}"} \
        ${optionalString (values != {}) "-f ${valuesJsonFile}"} \
        ${optionalString includeCRDs "--include-crds"} \
        ${optionalString noHooks "--no-hooks"} \
        ${chart} >$out
  '';
in
runCommand "${name}.json" { } ''
  # Remove null values
  ${yq}/bin/yq -Scs 'walk(
    if type == "object" then
      with_entries(select(.value != null))
    elif type == "array" then
      map(select(. != null))
    else
      .
    end)' ${resourcesYaml} >$out
''
