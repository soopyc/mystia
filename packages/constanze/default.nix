{
  lib,
  buildGoModule,
  fetchFromForgejo,
}:
buildGoModule {
  pname = "constanze";
  version = "2025-10-05+65312f2";

  vendorHash = "sha256-6C3OTAKAgZFeCteQpKVdC2gY18bzJST951QL2HnoGkM=";
  src = fetchFromForgejo {
    domain = "akkoma.dev";
    owner = "AkkomaGang";
    repo = "constanze";
    rev = "65312f2a4e08c7f636a1f0bd4d093e8e80f3b469";
    hash = "sha256-z+XdqHY2dJi2VoCOv2iIfCRMifY0ffHxS/zJTWFYuLg=";

    forceFetchGit = true; # tarball retrieval is flaky
  };

  meta = {
    description = "Simple CLI tool to tinker with akkoma instances";
    homepage = "https://akkoma.dev/AkkomaGang/constanze";
    maintainers = with lib.maintainers; [ soopyc ];
  };
}
