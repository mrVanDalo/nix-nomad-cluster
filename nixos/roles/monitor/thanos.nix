{ machine, ... }:
{

  services.thanos.query = {
    enable = true;
    # also provides a StoreAPI-endpoint for other Query Instances
    grpc-address = "0.0.0.0:10911";
    http-address = "0.0.0.0:10912";
    store.addresses = [
      "127.0.0.0:10901"
    ];
  };

  # thanos sidecar to query promehteus
  services.thanos.sidecar.enable = true;
  services.prometheus.globalConfig.external_labels = {
    prometheus_id = machine.environment;
  };
}
