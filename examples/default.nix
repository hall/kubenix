{ system ? builtins.currentSystem
, evalModules ? (import ../. { }).evalModules.${system}
}:

{ registry ? "docker.io/gatehub" }:

{
  nginx-deployment = import ./nginx-deployment { inherit evalModules registry; };
}
