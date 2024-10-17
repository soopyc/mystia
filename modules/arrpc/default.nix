{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.arrpc;
in {
  options.services.arrpc = {
    enable = lib.mkEnableOption "arRPC, a Discord RPC bridge for atypical setups";
    package = lib.mkPackageOption pkgs "arrpc" {};
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.arrpc = {
      enable = true;
      description = "Open source Discord RPC bridge for atypical setups";
      documentation = ["https://github.com/openasar/arrpc"];

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;

        Restart = "on-failure";
        RestartSec = 5;

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

      # ideally this would be socket triggered but i cannot figure out how to pass the socket to arrpc
      wantedBy = ["default.target"];
    };
  };

  meta.maintainers = with lib.maintainers; [soopyc];
}
