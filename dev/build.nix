{pkgs, ...}: {
  packages = with pkgs; [
    nix-prefetch-git
  ];

  tasks = {
    "ci:build:rift-wm" = {
      description = "Build rift-wm";
      exec = "nix build .#default";
    };
    "ci:build:rift-lua" = {
      description = "Build rift-lua";
      exec = "nix build .#rift-lua";
    };
    "ci:update" = {
      description = "Update rift-wm";
      exec = ''
        set -euo pipefail

        # ─── rift-wm
        echo "--- rift-wm ---"

        RIFT_OWNER="acsandmann"
        RIFT_REPO="rift"
        RIFT_FILE="rift.nix"

        RIFT_VERSION=$(curl -s "https://api.github.com/repos/$RIFT_OWNER/$RIFT_REPO/releases/latest" | jq -r .tag_name | sed 's/^v//')
        echo "Latest rift-wm: $RIFT_VERSION"

        RIFT_CURRENT=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$RIFT_FILE" | head -1)

        if [ "$RIFT_VERSION" != "$RIFT_CURRENT" ]; then
          echo "Updating rift-wm: $RIFT_CURRENT -> $RIFT_VERSION"

          sed -i.bak 's|version = "[^"]*";|version = "'"$RIFT_VERSION"'";|' "$RIFT_FILE"

          RIFT_HASH=$(nix-prefetch-git --url "https://github.com/$RIFT_OWNER/$RIFT_REPO" --rev "v$RIFT_VERSION" | jq -r .hash)
          sed -i.bak 's|hash = [^;]*;|hash = "'"$RIFT_HASH"'";|' "$RIFT_FILE"

          sed -i.bak 's|cargoHash = [^;]*;|cargoHash = lib.fakeHash;|' "$RIFT_FILE"
          rm -f "$RIFT_FILE.bak"

          echo "Building rift-wm to extract cargoHash..."
          RIFT_BUILD=$(nix build .#default 2>&1 || true)
          CARGO_HASH=$(echo "$RIFT_BUILD" | grep -oP 'got:\s+\Ksha256-[A-Za-z0-9+/=]+' | head -1 || true)

          if [ -z "$CARGO_HASH" ]; then
            echo "ERROR: could not extract cargoHash"
            echo "$RIFT_BUILD" | tail -n 20
            exit 1
          fi

          sed -i.bak 's|cargoHash = lib.fakeHash;|cargoHash = "'"$CARGO_HASH"'";|' "$RIFT_FILE"
          rm -f "$RIFT_FILE.bak"

          nix build .#default
          git add "$RIFT_FILE"
          git diff --cached --quiet "$RIFT_FILE" || git commit --no-verify -m "feat(rift-wm): $RIFT_CURRENT -> $RIFT_VERSION"
          echo "rift-wm updated to $RIFT_VERSION"
        else
          echo "rift-wm already at $RIFT_VERSION"
        fi

        # ─── rift.lua

        echo ""
        echo "--- rift.lua ---"

        LUA_OWNER="acsandmann"
        LUA_REPO="rift.lua"
        LUA_FILE="rift-lua.nix"

        LUA_COMMIT=$(curl -s "https://api.github.com/repos/$LUA_OWNER/$LUA_REPO/commits/main" | jq -r .sha)
        LUA_DATE=$(curl -s "https://api.github.com/repos/$LUA_OWNER/$LUA_REPO/commits/main" | jq -r .commit.committer.date | cut -dT -f1)
        echo "Latest rift.lua: $LUA_COMMIT ($LUA_DATE)"

        LUA_CURRENT=$(sed -n 's/.*rev = "\([^"]*\)".*/\1/p' "$LUA_FILE" | head -1)

        if [ "$LUA_COMMIT" != "$LUA_CURRENT" ]; then
          LUA_CURRENT_SHORT=$(echo "$LUA_CURRENT" | cut -c1-8)
          LUA_COMMIT_SHORT=$(echo "$LUA_COMMIT" | cut -c1-8)
          echo "Updating rift.lua: $LUA_CURRENT_SHORT -> $LUA_COMMIT_SHORT"

          sed -i.bak 's|rev = "[^"]*";|rev = "'"$LUA_COMMIT"'";|' "$LUA_FILE"
          sed -i.bak 's|version = "[^"]*";|version = "0-unstable-'"$LUA_DATE"'";|' "$LUA_FILE"

          LUA_HASH=$(nix-prefetch-git --url "https://github.com/$LUA_OWNER/$LUA_REPO" --rev "$LUA_COMMIT" | jq -r .hash)
          sed -i.bak 's|hash = [^;]*;|hash = "'"$LUA_HASH"'";|' "$LUA_FILE"
          rm -f "$LUA_FILE.bak"

          nix build .#rift-lua
          git add "$LUA_FILE"
          git diff --cached --quiet "$LUA_FILE" || git commit --no-verify -m "feat(rift-lua): $LUA_CURRENT_SHORT -> $LUA_COMMIT_SHORT"
          echo "rift.lua updated to $LUA_COMMIT_SHORT"
        else
          echo "rift.lua already at $(echo "$LUA_COMMIT" | cut -c1-8)"
        fi

        echo ""
        echo "Done."
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
