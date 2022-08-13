# nginx deployment

A simple example creating an nginx docker image and deployment.

## Usage

### Building and applying kubernetes configuration

    nix eval -f ./. --json result | kubectl apply -f -

### Building and pushing docker images

    nix run -f ./. pushDockerImages -c copy-docker-images

### Running tests

Test will spawn vm with Kubernetes and run test script, which checks if everything
works as expected.

    nix build -f ./. test-script
    cat result | jq '.'
