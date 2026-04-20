{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "subpipe";
  version = "2.1.2";

  src = fetchFromGitHub {
    owner = "shey-kail";
    repo = "subpipe";
    rev = "v${version}";
    hash = "sha256-2ZL0cnC3EK/jZqRCXwcmkQ3nqIiVMDNC63asQy4MoIs=";
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
