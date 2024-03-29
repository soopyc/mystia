{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;

  cfg = config.services.vmauth;
  yaml = pkgs.formats.yaml {};
  # definition of user stuff and etc.
  # or maybe we can just leave it out
in {
  options.services.vmauth = {
    enable = lib.mkEnableOption "vmauth, an authentication proxy for VictoriaMetrics services";
    package = lib.mkPackageOption pkgs "victoriametrics" {};

    listenAddress = mkOption {
      default = "127.0.0.1:8427";
      example = ":8443";
      description = "TCP address and port that vmauth should listen to.";
      type = types.str;
    };

    environmentFile = mkOption {
      description = ''
        Environment variables file passed to systemd for vmauth to make use of. See `authConfig` option for more details.

        Make the path a string (e.g. by surrounding it with double quotes `""`) to not let it end up in the world-readable nix store.
      '';
      type = types.nullOr types.str;
    };

    extraOptions = mkOption {
      description = "Extra CLI flags to pass to vmauth. See [the documentation](https://docs.victoriametrics.com/vmauth/#advanced-usage) or run `vmauth -help` for more information.";
      type = types.listOf types.str;
      default = [];
    };

    authConfig = mkOption {
      description = ''
        Proxy configuration to be passed to vmauth. See [the documentation](https://docs.victoriametrics.com/vmauth/#auth-config)
        for more information. For secrets, please **do not** pass them directly here unless you're okay with them being world-readable at the nix store.

        As an alternative, you may use `%{ENV_VAR}` syntax along with an existing secret management tool and the `environmentFile` option.
      '';
      type = types.submodule {freeformType = yaml.type;};
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.vmauth = {
      description = "vmauth - Simple authentication proxy for VictoriaMetrics components";
      after = ["network.target"];
      startLimitBurst = 5;

      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "1s";
        DynamicUser = true;
        # TODO: vmauth does not seem to generate anything so StateDirectory might not be needed. See if this changes later.
        ExecStart = ''
          ${lib.getExe' cfg.package "vmauth"} \
            -auth.config=${yaml.generate "vmauth.yaml" cfg.authConfig} \
            -httpListenAddr=${cfg.listenAddress} \
            ${lib.escapeShellArgs cfg.extraOptions}
        '';

        # This should be fine (´・ω・｀)
        EnvironmentFile = cfg.environmentFile;
      };
    };
  };
}
