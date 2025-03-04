{
  lib,
  buildGoModule,
  fetchFromGitHub,
  unstableGitUpdater,
}:

buildGoModule rec {
  pname = "anubis";
  version = "0-unstable-2025-03-03";

  src = fetchFromGitHub {
    owner = "Xe";
    repo = "x";
    rev = "19f0d3d0c1b171ebc25176f777d034ffaa98a4be";
    hash = "sha256-9AcNjxy33FOpgSaVVYGfLkl+r6aV0L9+ouyHUoFOW5U=";
  };

  subPackages = [ "cmd/anubis" ];
  vendorHash = "sha256-V/SrgBMZkw9lM+hCM+/5AQKZ3/iTY9kI5Lj+Ch9/Sbc=";

  ldflags = [
    "-X within.website/x.Version=${version}"
  ];

  passthru.updater = unstableGitUpdater {
    hardcodeZeroVersion = true;
  };

  meta = {
    description = "HTTP connection soul-weighing PoW challenge proxy";
    homepage = "https://github.com/Xe/x/blob/master/cmd/anubis/README.md";
    licenses = with lib.licenses; [ cc0 ];

    maintainers = with lib; [ soopyc ];
    mainProgram = "anubis";
  };
}
