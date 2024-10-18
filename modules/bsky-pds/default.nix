{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.services.bsky-pds;
in {
  options.services.bsky-pds = {
    enable = lib.mkEnableOption "Bluesky Personal Data Server (PDS)";
    package = lib.mkPackageOption pkgs "bsky-pds" {};

    initSecrets = mkOption {
      type = types.bool;
      description = ''
        Whether to automatically generate secrets for every required secret file not found.
        As of now this automcatically generates secrets for the JWT secret, admin password and the PLT rotation key.

        If you disable this option, you will have to manually generate the secrets.
        The commands to do so are listed in the PDS installation script.
      '';
      default = true;
    };

    # pds config definition
    settings = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf (types.oneOf (with types; [bool int str]));
        options = {
          PDS_HOSTNAME = mkOption {
            description = "The hostname of the PDS.";
            type = types.str;
            example = "bsky.example.com";
          };
          PDS_PORT = mkOption {
            description = "The port for the PDS to listen on";
            type = types.int;
            default = 2583;
          };
          # upstream "hardcoded" this to be /pds... try configuring it to see if it breaks anything.
          PDS_DATA_DIRECTORY = mkOption {
            description = "The data storage directory of the PDS. This hosts the database and the Blobstore.";
            type = types.str;
            default = "/var/lib/bsky-pds";
          };
          PDS_BLOBSTORE_DISK_LOCATION = mkOption {
            description = "The local Blobstore on-disk location. Support for S3 in this module is not planned at the moment.";
            defaultText = lib.literalExpression "\"\${settings.PDS_DATA_DIRECTORY}/blocks\"";
            default = "${cfg.settings.PDS_DATA_DIRECTORY}/blocks";
          };
          PDS_BLOB_UPLOAD_LIMIT = mkOption {
            description = "Presumably the file upload limit in bytes for the PDS.";
            type = types.int;
            default = 52428800;
          };
          PDS_DID_PLC_URL = mkOption {
            description = "The DID (Decentralized ID) PLC host's URL to use.";
            type = types.str;
            default = "https://plc.directory";
          };
          PDS_BSKY_APP_VIEW_URL = mkOption {
            description = "The Bluesky AppView's API to use.";
            type = types.str;
            default = "https://api.bsky.app";
          };
          PDS_BSKY_APP_VIEW_DID = mkOption {
            description = "The Bluesky AppView's DID.";
            type = types.str;
            default = "did:web:api.bsky.app";
          };
          PDS_REPORT_SERVICE_URL = mkOption {
            description = "The report service's API to use.";
            type = types.str;
            default = "https://mod.bsky.app";
          };
          PDS_REPORT_SERVICE_DID = mkOption {
            description = "The report service's DID.";
            type = types.str;
            default = "did:plc:ar7c4by46qjdydhdevvrndac";
          };
          PDS_CRAWLERS = mkOption {
            description = "i'm going to be honest i don't know what crawlers are apart from they crawl data from PDSes... but relays also do that.";
            type = types.str;
            default = "https://bsky.network";
          };
        };
      };
      description = ''
        Environment variable settings for the PDS. For a full list of available config options (without documentation),
        consult [the PDS source code](https://github.com/bluesky-social/atproto/blob/main/packages/pds/src/config/env.ts).
        The listing here only covers the bare minimum for the service to run, akin to the upstream install script.

        The settings description consists of various jargon, including terms such as AppView which may differ from what one might expect.
        It is encouraged to read the [ATProto Glossary](https://atproto.com/guides/glossary) to gain more insight.
      '';
    };

    credentials = mkOption {
      default = {};
      type = types.submodule {
        freeformType = types.attrsOf (types.oneOf (with types; [bool int str]));
        options = let
          mkFile = file: description:
            mkOption {
              type = types.str;
              default = "${cfg.settings.PDS_DATA_DIRECTORY}/${file}";
              defaultText = lib.literalExpression "\${settings.PDS_DATA_DIRECTORY}/${file}";
              description = "File path for ${description}";
            };
        in {
          PDS_JWT_SECRET = mkFile "jwt_key" "JWT signing secret";
          PDS_ADMIN_PASSWORD = mkFile "admin_passwd" "PDS administrator password";
          PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX = mkFile "plc_rotation_key" "PLC k256 hex format rotation key";
        };
      };
      description = ''
        Attribute list of environment variables stored as files outside of the Nix store for security.

        Each attribute should be a string pointing to a file, whose content will be replaced during service
        startup.

        If the file does not exist and [`initSecrets`] is enabled, known secret values will have a new secret
        generated and placed in the file specified.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.bsky-pds = {
      enable = true;
      description = "Bluesky Personal Data Server";
      documentation = ["https://github.com/bluesky-social/pds"];
      environment = builtins.mapAttrs (_: builtins.toString) cfg.settings;
      # This is golfed. full form should be builtins.mapAttrs (name: value: builtins.toString value) cfg.settings.

      preStart = lib.optionalString cfg.initSecrets ''
        set -euo pipefail

        fixPerms() {
          chmod 400 $1
        }
        touchFile() {
          touch $1 || true
          chmod 600 $1
        }

        ##### Secret generation phase #####
        if test ! -e ${cfg.credentials.PDS_JWT_SECRET}; then
          touchFile ${cfg.credentials.PDS_JWT_SECRET}
          ${lib.getExe pkgs.openssl} rand --hex 16 > ${cfg.credentials.PDS_JWT_SECRET}
          fixPerms ${cfg.credentials.PDS_JWT_SECRET}
        fi

        if test ! -e ${cfg.credentials.PDS_ADMIN_PASSWORD}; then
          touchFile ${cfg.credentials.PDS_ADMIN_PASSWORD}
          ${lib.getExe pkgs.openssl} rand --hex 16 > ${cfg.credentials.PDS_ADMIN_PASSWORD}
          fixPerms ${cfg.credentials.PDS_ADMIN_PASSWORD}
        fi

        if test ! -e ${cfg.credentials.PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX}; then
          touchFile ${cfg.credentials.PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX}
          ${lib.getExe pkgs.openssl} ecparam --name secp256k1 --genkey --noout --outform DER | \
            tail --bytes=+8 | \
            head --bytes=32 | \
            ${lib.getExe pkgs.unixtools.xxd} --plain --cols 32 > ${cfg.credentials.PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX}
          fixPerms ${cfg.credentials.PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX}
        fi
      '';

      script = ''
        ##### Pre-flight check and variable loading phase #####
        ${
          builtins.concatStringsSep "\n" (lib.forEach (lib.attrsToList cfg.credentials) ({
            name,
            value,
          }: ''
            if test ! -e ${value}; then
              echo "Secret file for variable ${name} does not exist: ${value}"
              exit 1
            fi
            export ${name}=$(cat ${value})
          ''))
        }

        ##### Launch phase #####
        ${lib.getExe cfg.package}
      '';

      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 10;

        DynamicUser = true;
        User = "bsky-pds";
        StateDirectory = "bsky-pds";

        # Hardening - not sure how many of these are superfluous.
        PrivateTmp = true;
        PrivateUsers = true;
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        CapabilityBoundingSet = null;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "@pkey"
          "~@privileged"
          "~@resources"
        ];
        RestrictAddressFamilies = [
          "AF_INET"
        ];
      };

      wantedBy = ["multi-user.target"];
    };
  };

  meta.maintainers = with lib.maintainers; [soopyc];
}
