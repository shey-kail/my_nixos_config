final: prev: {
  rPackages = prev.rPackages // {
    httpgd = prev.rPackages.httpgd.overrideAttrs (oldAttrs: {
      meta = (oldAttrs.meta or { }) // { broken = false; };
    });
    unigd = prev.rPackages.unigd.overrideAttrs (oldAttrs: {
      meta = (oldAttrs.meta or { }) // { broken = false; };
    });
  };
}