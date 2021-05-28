{ kubenix ? (import ./.. { }).default }:

{
  nginx-deployment = import ./nginx-deployment { inherit kubenix; };
}
