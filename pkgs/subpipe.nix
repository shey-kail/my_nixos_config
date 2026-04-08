{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "subpipe";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "shey-kail";
    repo = "subpipe";
    rev = "v${version}";
    hash = "sha256-Dz95P+rYycq98/e+zkv8MyCxBFsxyTxpH7Ic6iuhnc8=";
  };

  cargoHash = "sha256-lUt12gUqUGCC3Lm/fI1SQNoQW83RP+17yqnisfpJnJk=";

  doCheck = false;

  meta = with lib; {
    description = "A lightweight subscription converter for proxy protocols";
    homepage = "https://github.com/shey-kail/subpipe";
    license = licenses.mit;
    maintainers = with maintainers; [ sheykail ];
    platforms = platforms.linux;
  };
}
