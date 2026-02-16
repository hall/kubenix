{
  deployment = import ./deployment { };
  helm = import ./helm { };
  image = import ./image { };
  namespaces = import ./namespaces { };
  pod = import ./pod { };
  testing = import ./testing { };
  custom-resources = import ./custom-resources { };
}
