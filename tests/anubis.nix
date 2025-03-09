{ testers }:

{ module }:

testers.runNixOSTest {
  name = "anubis-basic";

  defaults = {
    imports = [ module ];
  };

  nodes.machine =
    { config, ... }:
    {
      services.anubis.instances = {
        "default".settings.TARGET = "https://example.com"; # default

        "tcp".settings = {
          TARGET = "https://example.com";
          BIND = ":9000";
          BIND_NETWORK = "tcp";
          METRICS_BIND = ":9001";
          METRICS_BIND_NETWORK = "tcp";
        };
      };

      # support
      users.users.nginx.extraGroups = [ config.users.groups.anubis.name ];
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        virtualHosts."localhost".locations = {
          # "http://unix:/run/anubis/anubis-default.sock";
          "/".proxyPass = "http://unix:${config.services.anubis.instances.default.settings.BIND}";

          # "http://unix:/run/anubis/anubis-default.sock";
          "/metrics".proxyPass =
            "http://unix:${config.services.anubis.instances.default.settings.METRICS_BIND}";
        };
      };
    };

  testScript = ''
    machine.wait_for_unit("anubis-default.service")
    machine.wait_for_unit("anubis-tcp.service")

    machine.succeed('curl -f http://localhost -H "User-Agent: Mozilla" | grep anubis')
    machine.succeed('curl -f http://localhost/metrics | grep anubis_challenges_issued')

    machine.succeed('curl -f localhost:9000 -H "User-Agent: Mozilla" | grep anubis')
    machine.succeed('curl -f localhost:9001/metrics | grep anubis_challenges_issued')
  '';
}
