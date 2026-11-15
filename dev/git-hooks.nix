{
  lib,
  config,
  ...
}: let
  If = lib.mkIf;
in {
  git-hooks = {
    enable = true;

    hooks = {
      treefmt.enable = If config.treefmt.enable true;
      editorconfig-checker.enable = true;
      gitleaks.enable = true;
      typos = {
        enable = true;
        settings.exclude = [
          ".sops.yaml"
          "secrets.enc.yaml"
        ];
      };
      deadnix.enable = true;
      statix.enable = true;
      markdownlint.enable = true;
      yamllint = {
        enable = true;
        settings.preset = "relaxed";
      };
      actionlint.enable = true;
      shellcheck.enable = true;
    };
  };
}
