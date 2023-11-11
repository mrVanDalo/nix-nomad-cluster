job "jaeger-demo-hotrod" {
  datacenters = ["dc1"]

  group "hotrod" {
    network {
      mode = "bridge"
    }

    service {
      name = "jaeger-hotrod"
      port = 8080
      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.hotrod.rule=Host(`hotrod.apps.cluster`)",
      ]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger-otlp-grpc"
              local_bind_port  = "4318"
            }
          }
        }
      }

    }

    task "hotrod" {
      driver = "docker"
      config {
        image   = "jaegertracing/example-hotrod:latest"
        command = "all"
        args = [
          "--jaeger-ui", "http://jaeger.apps.cluster",
        ]
      }
      env {
        OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"
      }
    }
  }

}