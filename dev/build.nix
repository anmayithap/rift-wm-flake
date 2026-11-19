{
  lib,
  pkgs,
  ...
}: {
  tasks = {
    "ci:build" = {
      description = "Build rift-wm";
      exec = "nix build .#default";
    };
    "ci:update" = {
      description = "Update rift-wm";
      exec = ''
        set -euo pipefail
        OWNER="acsandmann"
        REPO="rift"
        FILE="rift.nix"

        echo "Fetching latest release..."
        VERSION=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | jq -r .tag_name | sed 's/^v//')
        echo "Latest: $VERSION"

        CURRENT=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$FILE" | head -1)
        if [ "$VERSION" = "$CURRENT" ]; then
          echo "Already at $VERSION, nothing to do"
          exit 0
        fi

        sed -i.bak 's|version = ".*";|version = "'"$VERSION"'";|' "$FILE"

        echo "Prefetching src hash..."
        HASH=$(${lib.getExe pkgs.nix-prefetch-git} --url "https://github.com/$OWNER/$REPO" --rev "v$VERSION" | jq -r .hash)

        if ! grep -q 'hash = lib.fakeHash;' "$FILE"; then
          echo "WARNING: hash = lib.fakeHash not found, manual fix may be needed"
        fi
        sed -i.bak 's|hash = lib.fakeHash;|hash = "'"$HASH"'";|' "$FILE"

        echo "Building to extract cargoHash..."
        BUILD_OUT=$(nix build .#default 2>&1 || true)
        CARGO_HASH=$(echo "$BUILD_OUT" | grep -oP 'got:\s+\Ksha256-[A-Za-z0-9+/=]+' | head -1 || true)

        if [ -z "$CARGO_HASH" ]; then
          echo "ERROR: could not extract cargoHash. Build output:"
          echo "$BUILD_OUT"
          exit 1
        fi

        if ! grep -q 'cargoHash = lib.fakeHash;' "$FILE"; then
          echo "WARNING: cargoHash = lib.fakeHash not found, manual fix may be needed"
        fi
        sed -i.bak 's|cargoHash = lib.fakeHash;|cargoHash = "'"$CARGO_HASH"'";|' "$FILE"

        rm -f "$FILE.bak"

        nix build .#default

        git add "$FILE"
        git diff --cached --quiet "$FILE" || git commit --no-verify -m "feat(rift-wm): $CURRENT -> $VERSION"
        echo "Done: rift-wm $VERSION"
      '';
    };
    "ci:upgrade" = {
      description = "Update flake inputs";
      exec = ''
        set -euo pipefail
        nix flake update
        git add flake.lock
        git diff --cached --quiet flake.lock || git commit -m "feat(flake.lock): update"
        echo "flake.lock updated"
      '';
    };
  };
}
