{
  pkgs,
  ...
}: with pkgs;
let
  # Override httpgd to mark it as not broken
  R-with-my-packages = rWrapper.override{
    packages = with rPackages; [
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
