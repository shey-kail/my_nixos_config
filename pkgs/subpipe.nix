{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "subpipe";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "shey-kail";
    repo = "subpipe";
    rev = "v${version}";
    hash = "sha256-jcpQuGm145ViqWcwi972gwUBX0tqJKZyel+2//B9QD4=";
  };

  cargoHash = "sha256-sB/oJJH6tLZY0KQbZR7AajFMASB87J5A6UjC8lmnQ+g=";

  doCheck = false;

  meta = with lib; {
    description = "A lightweight subscription converter for proxy protocols";
    homepage = "https://github.com/shey-kail/subpipe";
    license = licenses.mit;
    maintainers = with maintainers; [ sheykail ];
    platforms = platforms.linux;
  };
}
