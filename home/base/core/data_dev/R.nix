{
  pkgs,
  ...
}:
let
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
      ### data processing
      tidyverse
      furrr
      future_apply
      multidplyr

      ### GO analysis
      clusterProfiler
      AnnotationHub
      AnnotationHubData

      ### plot
      cowplot
      ggtree
      ggfun
      ggprism
      ggpubr
      ggsci
      ggsignif
      ggedit
      ggupset
      ggVennDiagram
      ggrepel
      ggsankeyfier

      tidyplots

      patchwork
      httpgd
      fanyi
      yulab_utils
      RIdeogram
      CMplot

      ### DEGS
      DESeq2
      edgeR

      # SingleCell
      SingleCellExperiment
      Seurat

      # utils
      optparse
    ];
  };
in
{
  home.packages = [
    R-with-my-packages
  ];
}
