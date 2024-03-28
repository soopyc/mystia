{
  buildGoModule,
  fetchFromGitea,
}:
buildGoModule {
  pname = "constanze";
  version = "0.0.1-372b8ec";

  vendorHash = "sha256-6C3OTAKAgZFeCteQpKVdC2gY18bzJST951QL2HnoGkM=";
  src = fetchFromGitea {
    domain = "akkoma.dev";
    owner = "AkkomaGang";
    repo = "constanze";
    rev = "372b8ec304447133f1c7d6cdee44fc6a09a51440";
    hash = "sha256-LGkff92PaOj+0ZyFDr0FCuZ2w1hbD++OQxHSPbm3W88=";
  };

  meta = {
    description = "Simple CLI tool to tinker with akkoma instances";
    homepage = "https://akkoma.dev/AkkomaGang/constanze";
    maintainers = [(import ../maintainers/soopyc.nix)];
  };
}
