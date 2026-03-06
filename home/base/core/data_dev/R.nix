{
  pkgs,
  ...
}: let
  # Create a local pkgs instance that allows broken packages
  # This is much cleaner than a global nixpkgs.config.allowBroken = true;
  # because it only affects THIS specific R environment.
  pkgs-allow-broken = import pkgs.path {
    system = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config // {
      allowBroken = true;
    };
    # We should also pass overlays if they are needed, 
    # but here we can just use the base packages since we want unigd.
  };

  R-with-my-packages = pkgs-allow-broken.rWrapper.override {
    packages = with pkgs-allow-broken.rPackages; [
      tidyverse
      tidytable
      clusterProfiler
      ggtree
      AnnotationHub
      AnnotationHubData
      cowplot
      furrr
      future_apply
      multidplyr
      ggfun
      ggprism
      ggpubr
      ggsci
      ggsignif
      httpgd
      optparse
      patchwork
      fanyi
      DESeq2
      yulab_utils
      CMplot
      RIdeogram
      languageserver
    ];
  };
in {
  home.packages = [
    R-with-my-packages
  ];
}
