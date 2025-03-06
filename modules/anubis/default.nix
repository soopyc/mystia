self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  jsonFormat = pkgs.formats.json { };

  cfg = config.services.anubis;
  enabledInstances = (lib.filterAttrs (_: conf: conf.enable) cfg.instances);

  commonSubmodule =
    isDefault:
    let
      # "mkOptionWithPotentialDefaults" but it's too long
      mkDefaultOption =
        path: opts:
        lib.mkOption (
          opts
          // lib.optionalAttrs (!isDefault && opts ? default) {
            default = lib.attrByPath (lib.splitString "." path) (throw "anubis module bug") cfg.defaultOptions;
            defaultText = lib.literalExpression "config.services.anubis.defaultOptions.${path}";
          }
        );
    in
    { name, ... }:
    {
      options = {
        enable = lib.mkEnableOption "enable this instance" // {
          default = true;
        };
        user = mkDefaultOption "user" {
          default = "anubis";
          description = "The user under which Anubis is run.";
          type = types.nullOr types.str;
        };
        group = mkDefaultOption "group" {
          default = "anubis";
          description = "The group under which Anubis is run.";
          type = types.nullOr types.str;
        };
        dynamicUser = mkDefaultOption "dynamicUser" {
          default = false;
          description = "Whether to run Anubis under a systemd dynamic user.";
          example = true;
          type = types.bool;
        };

        botPolicy = lib.mkOption {
          default = null;
          description = ''
            Anubis bot policy configuration. Set to `null` to use the baked-in policy which should be sufficient for
            most use-cases.

            Has no effect if `settings.POLICY_FNAME` is set to a different value.

            See [upstream docs](https://github.com/Xe/x/blob/4755ba2b524f50f634a186ea5440ed2d6daa868e/cmd/anubis/docs/policies.md)
            for details.
          '';
          type = types.nullOr (
            types.submodule {
              freeformType = jsonFormat.type;
            }
          );
        };
        extraFlags = mkDefaultOption "extraFlags" {
          default = [ ];
          description = "A list of extra flags to be passed to Anubis.";
          example = [ "-metrics-bind ''" ];
          type = types.listOf types.str;
        };

        settings = lib.mkOption {
          default = { };
          description = ''
            Freeform configuration via environment variables for Anubis.

            See [upstream documentation](https://github.com/Xe/x/blob/4755ba2b524f50f634a186ea5440ed2d6daa868e/cmd/anubis/README.md#setting-up-anubis)
            for a complete list of configuration options.
          '';
          type = types.submodule ([
            {
              freeformType = types.attrsOf (types.anything);

              options = {
                # with defaults
                ## BIND and METRICS_BIND set below as defaults don't really make sense
                BIND_NETWORK = mkDefaultOption "settings.BIND_NETWORK" {
                  default = "unix";
                  description = ''
                    The network type that Anubis should listen to.

                    Known values are listed explicitly but other values may be used as long as it is supported by Go.
                  '';
                  example = "tcp";
                  type = types.oneOf [
                    (types.enum [
                      "tcp"
                      "unix"
                    ])
                    types.str
                  ]; # for documentation
                };
                METRICS_BIND_NETWORK = mkDefaultOption "settings.METRICS_BIND_NETWORK" {
                  default = "unix";
                  description = ''
                    The network type that the metrics server should listen to.

                    Known values are listed explicitly but other values may be used as long as it is supported by Go.
                  '';
                  example = "tcp";
                  type = types.oneOf [
                    (types.enum [
                      "tcp"
                      "unix"
                    ])
                    types.str
                  ]; # for documentation
                };
                SOCKET_MODE = mkDefaultOption "settings.SOCKET_MODE" {
                  default = "0770";
                  description = "The permissions on the Unix domain sockets created.";
                  example = "0700";
                  type = types.str;
                };
                DIFFICULTY = mkDefaultOption "settings.DIFFICULTY" {
                  default = 5;
                  description = ''
                    The difficulty required for clients to solve the challenge.

                    Currently, this means the amount of leading zeros in a successful response.
                  '';
                  type = types.int;
                  example = 4;
                };
                SERVE_ROBOTS_TXT = mkDefaultOption "settings.SERVE_ROBOTS_TXT" {
                  default = false;
                  description = ''
                    Whether to serve a default robots.txt that denys access to common AI bots by name and all other bots
                    by wildcard.
                  '';
                };

                # generated by default
                POLICY_FNAME = mkDefaultOption "settings.POLICY_FNAME" {
                  default = null;
                  description = ''
                    Bot policy file to use. Leave this as `null` to respect the
                    {option}`services.anubis.instances.<name>.botPolicy` option.
                  '';
                  type = types.nullOr types.path;
                };
              };
            }
            (lib.optionalAttrs (!isDefault) (instanceSpecificOptions name))
          ]);
        };
      };
    };

  instanceSpecificOptions = name: {
    options = {
      # see other options above
      BIND = lib.mkOption {
        default = "/run/anubis/anubis-${name}.sock";
        description = ''
          The address Anubis listens to, see Go's [net.Listen](https://pkg.go.dev/net#Listen) for syntax.

          Defaults to Unix domain sockets. To use TCP sockets, set this to a TCP address and BIND_NETWORK to `"tcp"`.
        '';
        example = ":8080";
        type = types.str;
      };
      METRICS_BIND = lib.mkOption {
        default = "/run/anubis/anubis-${name}-metrics.sock";
        description = ''
          The address Anubis' metrics server should listen to, see Go's [net.Listen](https://pkg.go.dev/net#Listen) for
          syntax.

          Defaults to Unix domain sockets. To use TCP sockets, set this to a TCP address and BIND_NETWORK to `"tcp"`.
        '';
        example = ":8081";
        type = types.str;
        # technically this can be disabled but flagenv/whatever ignores empty envs, so only possible by setting a flag.
      };
      TARGET = lib.mkOption {
        description = ''
          The reverse proxy target that Anubis is in front of. This is a required option.
        '';
        example = "http://127.0.0.1:8000";
        type = types.str;
      };
    };
  };
in
{
  options.services.anubis = {
    package = lib.mkPackageOption self.packages.${pkgs.system} "anubis-unix" { };

    createDefaultUser =
      lib.mkEnableOption ''
        create a default Anubis user.

        This only takes effect if at least one Anubis instance is defined and enabled
      ''
      // {
        default = true;
      };

    defaultOptions = lib.mkOption {
      default = { };
      description = "Default options for all instances of Anubis, unless overridden.";
      type = types.submodule (commonSubmodule true);
    };

    instances = lib.mkOption {
      default = { };
      description = "Attribute set of Anubis instances. A name must be set.";
      type = types.attrsOf (types.submodule (commonSubmodule false));
    };
  };

  config = lib.mkIf (enabledInstances != { }) {
    assertions = [
      {
        assertion = !lib.any (name: name == "") (builtins.attrNames enabledInstances);
        message = "All Anubis instances must have a name, for example `default`";
      }
    ];

    users = lib.mkIf cfg.createDefaultUser {
      users.anubis = {
        isSystemUser = true;
        group = "anubis";
      };
      groups.anubis = { };
    };

    systemd.services = lib.mapAttrs' (
      name: instance:
      lib.nameValuePair "anubis-${name}" {
        description = "Anubis (${name} instance)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        environment = builtins.mapAttrs (lib.const (lib.generators.mkValueStringDefault { })) (
          lib.filterAttrs (_: v: v != null) instance.settings
        );

        serviceConfig = {
          User = instance.user;
          Group = instance.group;
          DynamicUser = instance.dynamicUser;
          ExecStart = builtins.concatStringsSep " " (
            (lib.singleton (lib.getExe cfg.package)) ++ instance.extraFlags
          );
          RuntimeDirectory =
            if
              builtins.any (lib.hasPrefix "/run/anubis") (
                with instance.settings;
                [
                  BIND
                  METRICS_BIND
                ]
              )
            then
              "anubis"
            else
              null;
        };
      }
    ) enabledInstances;
  };

  meta.maintainers = with lib.maintainers; [ soopyc ];
}
