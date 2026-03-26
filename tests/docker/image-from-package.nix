{ images
, evalModules
, pkgs
, ...
}:
let
  moduleWithCompat = evalModules {
    modules = [
      ({ kubenix, ... }: {
        imports = [ kubenix.modules.docker-image-from-package ];
        docker = {
          registry.url = "old-registry:5000";
          images.curl1.image = images.curl;
        };
      })
    ];
  };

  moduleWithoutCompat = evalModules {
    modules = [
      ({ kubenix, ... }: {
        imports = [ kubenix.modules.docker ];
        docker = {
          registry.host = "new-registry:5000";
          images.curl1.image = images.curl;
        };
      })
    ];
  };
in
pkgs.testers.runNixOSTest {
  name = "docker-image-from-package";

  nodes.client = {
    environment.systemPackages = [
      moduleWithCompat.config.docker.copyScript
      moduleWithoutCompat.config.docker.copyScript
      pkgs.skopeo
    ];
  };

  testScript = ''
    # Test 1: Verify old registry.url maps to registry.host
    assert "${moduleWithCompat.config.docker.registry.host}" == "old-registry:5000", \
      "Expected registry.host to be 'old-registry:5000'"

    # Test 2: Verify name/tag defaults use package values
    curl1_name = "${moduleWithCompat.config.docker.images.curl1.name}"
    curl1_tag = "${moduleWithCompat.config.docker.images.curl1.tag}"
    assert curl1_name == "curl", f"Expected curl1 name to be 'curl', got: {curl1_name}"
    assert curl1_tag == "latest", f"Expected curl1 tag to be 'latest', got: {curl1_tag}"

    # Test 3: Verify path is correctly constructed
    curl1_path = "${moduleWithCompat.config.docker.images.curl1.path}"
    assert curl1_path == "old-registry:5000/curl:latest", \
      f"Expected curl1 path to be 'old-registry:5000/curl:latest', got: {curl1_path}"

    # Test 4: Verify uri is correctly constructed
    curl1_uri = "${moduleWithCompat.config.docker.images.curl1.uri}"
    assert curl1_uri == "docker://old-registry:5000/curl:latest", \
      f"Expected curl1 uri to be 'docker://old-registry:5000/curl:latest', got: {curl1_uri}"

    # Test 5: Verify module without compat works normally
    new_curl1_path = "${moduleWithoutCompat.config.docker.images.curl1.path}"
    assert new_curl1_path == "new-registry:5000/curl:latest", \
      f"Expected new curl1 path to be 'new-registry:5000/curl:latest', got: {new_curl1_path}"

    start_all()
    client.succeed("echo 'Tests passed'")
  '';
}
