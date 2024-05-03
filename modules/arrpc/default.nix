{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.arrpc;
in
{
  options.services.arrpc = {
    enable = lib.mkEnableOption "a Discord RPC bridge for atypical setups";
    package = lib.mkPackageOption pkgs "arrpc" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.arrpc = {
      enable = true;
      description = "Open Discord RPC bridge for atypical setups";
      documentation = ["https://github.com/openasar/arrpc"];

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;

        # Hardening - not sure how many of these are superfluous.
        PrivateTmp = true;
        PrivateUsers = true;
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        CapabilityBoundingSet = null; # seems to work
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "@pkey"
          "~@privileged"
          "~@resources"
        ];
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
        ];
      };

      wantedBy = [ "default.target" ];
    };
  };

  meta.maintainers = with lib.maintainers; [ soopyc ];
}
