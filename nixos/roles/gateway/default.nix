{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  networking.hostName = lib.mkDefault "gateway";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  environment.systemPackages = [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.python3
  ];

  # gateway
  components.network.routing.enable = false;
  networking.nat = {
    enable = true;
    internalIPs = [ "10.0.0.0/24" ];
  };

  system.stateVersion = "23.11";
}
