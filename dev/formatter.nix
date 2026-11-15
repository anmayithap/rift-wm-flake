{
  treefmt = {
    enable = true;

    config.projectRootFile = "devenv.nix";

    config.programs = {
      prettier.enable = true;
      taplo.enable = true;
      alejandra.enable = true;
    };
  };
}
