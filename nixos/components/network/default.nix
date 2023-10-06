{ config, pkgs, lib, ... }:
with lib;
with types;
{
  options.components.network = {
    enable = mkOption {
      type = bool;
      default = true;
    };
  };

  imports = [
    ./ssh.nix
    ./routing.nix
    ./systemd.nix
  ];

  config = mkIf config.components.network.enable { };
}
