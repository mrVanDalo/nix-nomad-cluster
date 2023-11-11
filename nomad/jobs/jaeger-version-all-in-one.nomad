job "jaeger" {
  datacenters = ["dc1"]

  # this is just for testing
  group "all-in-one" {
    network {
      mode = "bridge"
    }

    service {
      name = "jaeger-ui"
      port = 16686
      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.jeager.rule=Host(`jaeger.apps.cluster`)",
      ]
      connect {
        sidecar_service {}
      }
    }

    service {
      name = "jaeger-otlp-grpc"
      port = 4318
      connect {
        sidecar_service {}
      }
    }

    task "all-in-one" {
      driver = "docker"
      config {
        image = "jaegertracing/all-in-one:latest"
      }
      env {
        LOG_LEVEL = "debug"
      }
    }
  }

}