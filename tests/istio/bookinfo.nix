{ kubenix, ... }: {
  imports = with kubenix.modules; [ test k8s istio ];

  test = {
    name = "istio-bookinfo";
    description = "Simple istio bookinfo application (WIP)";
  };

  kubernetes.api."networking.istio.io"."v1alpha3" = {
    Gateway."bookinfo-gateway" = {
      spec = {
        selector.istio = "ingressgateway";
        servers = [
          {
            port = {
              number = 80;
              name = "http";
              protocol = "HTTP";
            };
            hosts = [ "*" ];
          }
        ];
      };
    };

    VirtualService.bookinfo = {
      spec = {
        hosts = [ "*" ];
        gateways = [ "bookinfo-gateway" ];
        http = [
          {
            match = [
              {
                uri.exact = "/productpage";
              }
              {
                uri.exact = "/login";
              }
              {
                uri.exact = "/logout";
              }
              {
                uri.prefix = "/api/v1/products";
              }
            ];
            route = [
              {
                destination = {
                  host = "productpage";
                  port.number = 9080;
                };
              }
            ];
          }
        ];
      };
    };

    DestinationRule.productpage = {
      spec = {
        host = "productpage";
        subsets = [
          {
            name = "v1";
            labels.version = "v1";
          }
        ];
      };
    };

    DestinationRule.reviews = {
      spec = {
        host = "reviews";
        subsets = [
          {
            name = "v1";
            labels.version = "v1";
          }
          {
            name = "v2";
            labels.version = "v2";
          }
          {
            name = "v3";
            labels.version = "v3";
          }
        ];
      };
    };

    DestinationRule.ratings = {
      spec = {
        host = "ratings";
        subsets = [
          {
            name = "v1";
            labels.version = "v1";
          }
          {
            name = "v2";
            labels.version = "v2";
          }
          {
            name = "v2-mysql";
            labels.version = "v2-mysql";
          }
          {
            name = "v2-mysql-vm";
            labels.version = "v2-mysql-vm";
          }
        ];
      };
    };

    DestinationRule.details = {
      spec = {
        host = "details";
        subsets = [
          {
            name = "v1";
            labels.version = "v1";
          }
          {
            name = "v2";
            labels.version = "v2";
          }
        ];
      };
    };
  };
}
