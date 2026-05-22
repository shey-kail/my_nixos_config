{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "subpipe";
  version = "2.2.2";

  src = fetchFromGitHub {
    owner = "shey-kail";
    repo = "subpipe";
    rev = "v${version}";
    hash = "sha256-ZjJ345c4zjX1FsJKz7gqyDIQZqgi3ewf6TTrsYZ8RbQ=";
  };
  cargoHash = "sha256-MtoAaE/vy58xpEqzzI9fvAi76+Vy6L9L7/PfQqNqXsk=";

  doCheck = false;

  meta = with lib; {
    description = "A lightweight subscription converter for proxy protocols";
    homepage = "https://github.com/shey-kail/subpipe";
    license = licenses.mit;
    maintainers = with maintainers; [ sheykail ];
    platforms = platforms.linux;
  };
}
