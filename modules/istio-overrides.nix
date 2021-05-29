{ lib, definitions }:

with lib;

{
  "istio_networking_v1alpha3_StringMatch" = recursiveUpdate
    (recursiveUpdate
      definitions."istio_networking_v1alpha3_StringMatch_Exact"
      definitions."istio_networking_v1alpha3_StringMatch_Prefix"
    )
    definitions."istio_networking_v1alpha3_StringMatch_Regex";

  "istio_networking_v1alpha3_PortSelector" = recursiveUpdate
    definitions."istio_networking_v1alpha3_PortSelector_Name"
    definitions."istio_networking_v1alpha3_PortSelector_Number";
}
