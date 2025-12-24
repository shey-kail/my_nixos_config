{
  config,
  ...
}: let
  shellAliases = {
    urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
    urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
  };

  localBin = "${config.home.homeDirectory}/.local/bin";
#  goBin = "${config.home.homeDirectory}/go/bin";
#  rustBin = "${config.home.homeDirectory}/.cargo/bin";
in {
  # only works in bash/zsh, not nushell
  home.shellAliases = shellAliases;

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:${localBin}"
    '';
    #  # enable micromamba
    #  initExtra = ''
    #    set -e
    #    if [[ $FHS == "micromamba_env" ]] ; then
    #      eval "$(micromamba shell hook --shell bash)" 
    #    fi
    #    set +e
    #  '';
  };
}
