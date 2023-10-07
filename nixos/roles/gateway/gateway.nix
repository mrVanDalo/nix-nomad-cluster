{
  # gateway
  components.network.hetzner.enable = false;
  networking.nat = {
    enable = true;
    # todo : make dynamic
    internalIPs = [ "10.0.0.0/20" ];
  };
}
