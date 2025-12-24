final: prev: {
  rPackages = prev.rPackages // {
    httpgd = prev.rPackages.httpgd.overrideAttrs (oldAttrs: {
      meta = oldAttrs.meta // { broken = false; };
    });
  };
}