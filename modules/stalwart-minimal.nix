# adapted from https://github.com/NixOS/nixpkgs/blob/a263060feafdfdb5d1d70b53b04d5bb810b13cf1/nixos/modules/services/mail/stalwart.nix
_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.services.stalwart-minimal;
  json = pkgs.formats.json { };
in
{
  options.services.stalwart-minimal = {
    # this module is deliberately minimal so i don't step on my own toes.
    # ...but it *will* miss out on convenience features.

    enable = lib.mkEnableOption "a minimized module of `services.stalwart`";
    package = lib.mkPackageOption pkgs "stalwart" { };

    user = lib.mkOption {
      type = types.str;
      default = "stalwart";
      description = "The user to run stalwart as.";
    };
    group = lib.mkOption {
      type = types.str;
      default = "stalwart";
      description = "The group to run stalwart with.";
    };

    credentials = lib.mkOption {
      type = types.attrs;
      default = { };
      description = "attrset loaded to `systemd.services.stalwart.serviceConfig.LoadCredentials` in the right format.";
    };

    startupConfig = lib.mkOption {
      type = json.type;
      description = ''
        startup configuration file.

        for 0.16+, this can only be a DataStore object; see
        https://stalw.art/docs/ref/object/data-store/ for schema.

        defaults follow the documented defaults.
      '';
      default = {
        "@type" = "RocksDb";
        path = "/var/lib/stalwart/data";
        blobSize = 16384;
        bufferSize = 134217728;
      };
    };

    startupConfigFile = lib.mkOption {
      type = types.nullOr types.path;
      default = null;
      defaultText = "path generated from startupConfig";
      description = ''
        the actual file to pass to stalwart. if set to anything but null, overrides `startupConfig`.

        for bootstrap mode, set this to an initially non-existent file, like `/etc/stalwart/config.json`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      groups = lib.mkIf (cfg.group == "stalwart") {
        stalwart = { };
      };
      users = lib.mkIf (cfg.group == "stalwart") {
        stalwart = {
          isSystemUser = true;
          group = "stalwart";
        };
      };
    };

    environment.systemPackages = lib.singleton cfg.package;

    systemd = {
      packages = lib.singleton cfg.package;

      services.stalwart = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        unitConfig.ConditionPathExists = [ "" ]; # ??????? why does the service in pkg(0.16) point to a non-existent file
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          ExecStart = [
            ""
            "${lib.getExe cfg.package} --config=${lib.defaultTo (json.generate "stalwart-config.json" cfg.startupConfig) cfg.startupConfigFile}"
          ];

          CacheDirectory = "stalwart";
          StateDirectory = "stalwart";

          LoadCredential = lib.mapAttrsToList (name: value: "${name}:${value}") cfg.credentials;

          # AmbientCapabilities already set
          CapabilityBoundingSet = lib.singleton "CAP_NET_BIND_SERVICE";

          # Hardening
          UMask = "0077";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          PrivateDevices = true;
          PrivateUsers = false; # TODO: set to false if it breaks CAP_NET_BIND_SERVICE
          PrivateTmp = true;
          ProtectClock = true;
          ProtectProc = "invisible"; # kinda implies ProcSubset?
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];

          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
        };
      };
    };

    meta.maintainers = with lib.maintainers; [
      soopyc
    ];
  };
}
