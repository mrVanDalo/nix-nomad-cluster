{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix

    ./cache.nix
    #./proxy.nix
    #./proxy2.nix
  ];

  # todo : use this repo or something to make a proxy work (if this repo works)
  # https://github.com/pbek/nixcfg/tree/b8ed727902e99becfb4fb51277b6081cd853fa33/docker/nix-cache-nginx

  networking.hostName = lib.mkDefault "cache";

  system.stateVersion = "23.11";

}
