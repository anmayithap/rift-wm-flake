{
  lib,
  stdenv,
  fetchFromGitHub,
  lua5_5,
  pkg-config,
  apple-sdk,
}:
stdenv.mkDerivation {
  pname = "rift-lua";
  version = "0-unstable-2026-09-06";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift.lua";
    rev = "c5c087daf5da63e9b29e6c448ccabe364b7e13af";
    hash = "sha256-QFO3ed2zlmwSVfdvXxnxn80CNWiclOXW6V8OzgmogF4=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    lua5_5
    apple-sdk
  ];

  makeFlags = [
    "USE_SYSTEM_LUA=auto"
    "LUA=${lib.getExe lua5_5}"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/rift.so $out/lib/lua/${lua5_5.luaversion}/rift.so
    runHook postInstall
  '';

  meta = {
    description = "Lua Mach IPC client for rift-wm";
    homepage = "https://github.com/acsandmann/rift.lua";
    license = lib.licenses.asl20;
    platforms = lib.platforms.darwin;
  };
}
