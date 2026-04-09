{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "subpipe";
  version = "2.1.1";

  src = fetchFromGitHub {
    owner = "shey-kail";
    repo = "subpipe";
    rev = "v${version}";
    hash = "sha256-KYG1SAQh/IHDUhgOHuLHdu2SEfNPZai5lQY3EU7lrtI=";
  };

  cargoHash = "sha256-D/DRq9vK8dk2EInsIkcRAe1uufgaR8Zz4/27QUk4UAU=";

  doCheck = false;

  meta = with lib; {
    description = "A lightweight subscription converter for proxy protocols";
    homepage = "https://github.com/shey-kail/subpipe";
    license = licenses.mit;
    maintainers = with maintainers; [ sheykail ];
    platforms = platforms.linux;
  };
}
