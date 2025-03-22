{ testers }:

{ module }:

testers.runNixOSTest {
  name = "anubis-basic";

  defaults = {
    imports = [ module ];
  };

  nodes.machine =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.anubis.instances = {
        "default".settings.TARGET = "http://localhost:8080";

        "tcp".settings = {
          TARGET = "http://localhost:8080";
          BIND = ":9000";
          BIND_NETWORK = "tcp";
          METRICS_BIND = ":9001";
          METRICS_BIND_NETWORK = "tcp";
        };

        "unix-upstream" = {
          group = "nginx";
          settings.TARGET = "unix:///run/nginx/nginx.sock";
        };
      };

      # support
      users.users.nginx.extraGroups = [ config.users.groups.anubis.name ];
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        virtualHosts."basic.localhost".locations = {
          # http://unix:/run/anubis/anubis-default.sock
          "/".proxyPass = "http://unix:${config.services.anubis.instances.default.settings.BIND}";

          # http://unix:/run/anubis/anubis-default-metrics.sock
          "/metrics".proxyPass =
            "http://unix:${config.services.anubis.instances.default.settings.METRICS_BIND}";
        };

        # emulate an upstream with nginx, listening on tcp and unix sockets.
        virtualHosts."upstream.localhost" = {
          default = true; # make nginx match this vhost for `localhost`
          listen = [
            { addr = "unix:/run/nginx/nginx.sock"; }
            {
              addr = "localhost";
              port = 8080;
            }
          ];
          locations."/" = {
            tryFiles = "$uri $uri/index.html =404";
            root = pkgs.runCommand "anubis-test-upstream" { } ''
              mkdir $out
              echo "it works" >> $out/index.html
            '';
          };
        };
      };
    };

  testScript = ''
    machine.wait_for_unit("nginx.service")
    machine.wait_for_unit("anubis-default.service")
    machine.wait_for_unit("anubis-tcp.service")
    machine.wait_for_unit("anubis-unix-upstream.service")

    # Default unix socket mode
    machine.succeed('curl -f http://basic.localhost | grep "it works"')
    machine.succeed('curl -f http://basic.localhost -H "User-Agent: Mozilla" | grep anubis')
    machine.succeed('curl -f http://basic.localhost/metrics | grep anubis_challenges_issued')
    machine.succeed('curl -f -X POST http://basic.localhost/.within.website/x/cmd/anubis/api/make-challenge | grep challenge')

    # TCP mode
    machine.succeed('curl -f localhost:9000 -H "User-Agent: Mozilla" | grep anubis')
    machine.succeed('curl -f localhost:9001/metrics | grep anubis_challenges_issued')

    # Upstream is a unix socket mode
    machine.succeed('curl -f --unix-socket /run/anubis/anubis-unix-upstream.sock http://upstream.localhost/index.html | grep "it works"')
  '';
}
