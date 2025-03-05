{
  stdenvNoCC,
  bucketName ? "unknown-bucket",
  bucketUrl ? "https://example.com",
  bucketWebsiteUrl ? bucketUrl,
}:

stdenvNoCC.mkDerivation (final: {
  inherit bucketName bucketUrl bucketWebsiteUrl;

  pname = "s3-listing";
  version = "unstable-2025-02-14";

  src = ./listing.html;

  dontUnpack = true;

  patchPhase = ''
    mkdir $out
    substituteAll ${final.src} $out/listing.html
  '';
})
