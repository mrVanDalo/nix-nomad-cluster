{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix
  ];

  networking.hostName = lib.mkDefault "cache";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  system.stateVersion = "23.11";

  # try:
  # - disable networking.dhcpd and enable systemd network
  # - raise metric parameter on networkin.defaultGateway.metric
  # - disable dhcpd

}
