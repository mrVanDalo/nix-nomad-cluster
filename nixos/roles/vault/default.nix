{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix
  ];

  networking.hostName = lib.mkDefault "vault";
  components.network.routing.enable = false;
  components.network.systemd.enable = true;

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  system.stateVersion = "23.11";

}
