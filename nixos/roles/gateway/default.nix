{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix
  ];

  networking.hostName = lib.mkDefault "gateway";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # gateway
  components.network.routing.enable = false;
  networking.nat = {
    enable = true;
    internalIPs = [ "10.0.0.0/24" ];
  };

  system.stateVersion = "23.11";
}
