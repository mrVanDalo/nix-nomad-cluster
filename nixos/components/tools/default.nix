{ config, pkgs, lib, ... }:
with lib;
with types;
{
  options.components.tools = {
    enable = mkOption {
      type = bool;
      default = true;
    };
  };

  #imports = [ ];

  config = mkIf config.components.tools.enable {

    environment.systemPackages = [
      pkgs.curl
      pkgs.git
      pkgs.python3
      pkgs.vim
      pkgs.htop
      pkgs.silver-searcher
    ];

    environment.extraInit = ''
      # use vi shortcuts
      # ----------------
      set -o vi
      EDITOR=vim
    '';

  };
}
