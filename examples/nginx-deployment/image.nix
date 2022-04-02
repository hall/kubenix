{
  dockerTools,
  nginx,
}:
dockerTools.buildLayeredImage {
  name = "nginx";
  contents = [nginx];
  extraCommands = ''
    mkdir -p etc
    chmod u+w etc
    echo "nginx:x:1000:1000::/:" > etc/passwd
    echo "nginx:x:1000:nginx" > etc/group
  '';
  config = {
    Cmd = ["nginx" "-c" "/etc/nginx/nginx.conf"];
    ExposedPorts = {
      "80/tcp" = {};
    };
  };
}
