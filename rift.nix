{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  apple-sdk,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift-wm";
  version = "0.8.2";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${version}";
    hash = "sha256-cLFGVkPF7qGgC4QIyEc8b9rZ0LB8PoH7golgwT59ZRA=";
  };

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk
  ];

  cargoHash = "sha256-XFn/DXOimu4gkgOXKDgZ/RBVxida7mvq1+lMx0Wrt/4=";

  checkFlags = [
    "--skip=actor::reactor::tests::empty_active_space_membership_during_wake_race_does_not_blank_known_active_windows"
  ];

  meta = {
    description = "Tiling window manager for macOS";
    homepage = "https://github.com/acsandmann/rift";
    changelog = "https://github.com/acsandmann/rift/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "rift";
    platforms = lib.platforms.darwin;
  };
}
