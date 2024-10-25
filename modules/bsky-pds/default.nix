{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.services.bsky-pds;
  systemdHardening = {
    CapabilityBoundingSet = null;
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    PrivateUsers = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    RestrictAddressFamilies = [ "AF_INET" ];
    RestrictNamespaces = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = false;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    RemoveIPC = true;
    PrivateMounts = true;
    SystemCallArchitectures = "native";
  };
in
{
  options.services.bsky-pds = {
    enable = lib.mkEnableOption "Bluesky Personal Data Server (PDS)";
    package = lib.mkPackageOption pkgs "bsky-pds" { };

    initSecrets =
      lib.mkEnableOption {
        description = ''
          the generation of secrets for every required secret file not found.
          As of now this automcatically generates secrets for the JWT secret, admin password and the PLT rotation key.

          This will not overwrite existing secrets.

          If you disable this option, you will have to manually generate the secrets.
          The commands to do so are listed in the PDS installation script
        '';
      }
      // {
        default = true;
      };

    # pds config definition
    settings = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf (
          types.oneOf (
            with types;
            [
              bool
              int
              str
            ]
          )
        );
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
            description = "The file upload limit in bytes for the PDS.";
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
            description = ''
              The relays/crawlers to use for the PDS. These essentially aggregrate data so that your data actually show
              up in the Bluesky AppView.

              Ensure websockets are properly proxied for relays to work.
            '';
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
      default = { };
      type = types.submodule {
        freeformType = types.attrsOf types.str;
        options =
          let
            mkFile =
              file: description:
              mkOption {
                type = types.str;
                default = "${cfg.settings.PDS_DATA_DIRECTORY}/${file}";
                defaultText = lib.literalExpression "\${settings.PDS_DATA_DIRECTORY}/${file}";
                description = "File path for ${description}";
              };
          in
          {
            PDS_JWT_SECRET = mkFile "jwt_key" "JWT signing secret";
            PDS_ADMIN_PASSWORD = mkFile "admin_passwd" "PDS administrator password";
            PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX = mkFile "plc_rotation_key" "PLC rotation key";
          };
      };
      description = ''
        Attribute list of environment variables stored as files outside of the Nix store for security.

        Each attribute should be a string pointing to a file, whose content will be read and set as environment variables
        with the same name during service startup.

        If the file does not exist and [`initSecrets`] is enabled, known secret values will have a new secret
        generated and placed in the file specified.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = {
      bsky-pds = {
        enable = true;
        description = "Bluesky Personal Data Server";
        documentation = [ "https://github.com/bluesky-social/pds" ];
        environment = builtins.mapAttrs (_: builtins.toString) cfg.settings;
        # This is golfed. full form should be builtins.mapAttrs (name: value: builtins.toString value) cfg.settings.

        after = [
          "network-online.target"
          "bsky-pds-secrets.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "bsky-pds-secrets.service" ];

        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 10;
          ExecStart = lib.getExe cfg.package;

          DynamicUser = true;
          StateDirectory = "bsky-pds";

          # credentials
          # LoadCredential = lib.mapAttrsToList (name: value: "${name}:${value}") cfg.credentials;
          EnvironmentFile = [
            # should be safe to assume this file will exist during service startup as the secret service is ran.
            "${cfg.settings.PDS_DATA_DIRECTORY}/.secret.env"
          ];
        } // systemdHardening;

        wantedBy = [ "multi-user.target" ];
      };

      bsky-pds-secrets = {
        script = lib.concatLines [
          ##### Secret generation phase #####
          (lib.optionalString cfg.initSecrets ''
            if test ! -e ${cfg.credentials.PDS_JWT_SECRET}; then
              echo "Generating JWT secret..."
              ${lib.getExe pkgs.openssl} rand --hex 16 > '${cfg.credentials.PDS_JWT_SECRET}'
            fi

            if test ! -e ${cfg.credentials.PDS_ADMIN_PASSWORD}; then
              echo "Generating Admin Password..."
              ${lib.getExe pkgs.openssl} rand --hex 16 > '${cfg.credentials.PDS_ADMIN_PASSWORD}'
            fi

            # this command exists as-is in the official installation script, but i'm not sure if this is just a sophisticated way of running
            # openssl rand -hex 32 and if there are implications of doing so. i don't know anything about crypto so i will not touch this.
            if test ! -e ${cfg.credentials.PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX}; then
              echo "Generating PLC rotation key..."
              ${lib.getExe pkgs.openssl} ecparam --name secp256k1 --genkey --noout --outform DER | \
                tail --bytes=+8 | \
                head --bytes=32 | \
                ${lib.getExe pkgs.unixtools.xxd} --plain --cols 32 > '${cfg.credentials.PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX}'
            fi
          '')

          # should we also check if secrets exist here before setting the .env file?

          ##### Secret loading phase #####
          ''
            cat > "${cfg.settings.PDS_DATA_DIRECTORY}/.secret.env" <<EOF
            ${
              (lib.concatLines (
                lib.mapAttrsToList (name: value: ''
                  ${name}=$(cat ${value})
                '') cfg.credentials
              ))
            }
            EOF
          ''
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          UMask = "0077";

          # sandboxing - especially important here as we run as a privileged user to read credentials.
          PrivateNetwork = true;
          ReadWritePaths = [cfg.settings.PDS_DATA_DIRECTORY];
        } // systemdHardening;
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ soopyc ];
}
