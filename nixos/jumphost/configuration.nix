{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  networking.hostName = "jumphost";

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.python3
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6uza62+Go9sBFs3XZE2OkugBv9PJ7Yv8ebCskE5WYPcahMZIKkQw+zkGI8EGzOPJhQEv2xk+XBf2VOzj0Fto4nh8X5+Llb1nM+YxQPk1SVlwbNAlhh24L1w2vKtBtMy277MF4EP+caGceYP6gki5+DzlPUSdFSAEFFWgN1WPkiyUii15Xi3QuCMR8F18dbwVUYbT11vwNhdiAXWphrQG+yPguALBGR+21JM6fffOln3BhoDUp2poVc5Qe2EBuUbRUV3/fOU4HwWVKZ7KCFvLZBSVFutXCj5HuNWJ5T3RuuxJSmY5lYuFZx9gD+n+DAEJt30iXWcaJlmUqQB5awcB1S2d9pJ141V4vjiCMKUJHIdspFrI23rFNYD9k2ZXDA8VOnQE33BzmgF9xOVh6qr4G0oEpsNqJoKybVTUeSyl4+ifzdQANouvySgLJV/pcqaxX1srSDIUlcM2vDMWAs3ryCa0aAlmAVZIHgRhh6wa+IXW8gIYt+5biPWUuihJ4zGBEwkyVXXf2xsecMWCAGPWPDL0/fBfY9krNfC5M2sqxey2ShFIq+R/wMdaI7yVjUCF2QIUNiIdFbJL6bDrDyHnEXJJN+rAo23jUoTZZRv7Jq3DB/A5H7a73VCcblZyUmwMSlpg3wos7pdw5Ctta3zQPoxoAKGS1uZ+yTeZbPMmdbw=="
  ];

  system.stateVersion = "23.11";
}
