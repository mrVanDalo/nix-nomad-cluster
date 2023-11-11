# not working yet, see here for inspiration :
# https://github.com/jaegertracing/jaeger-kubernetes/blob/master/jaeger-production-template.yml
job "jaeger" {
  datacenters = ["dc1"]

  group "query" {
    network {
      mode = "bridge"
    }

    service {
      name = "jaeger-query"
      port = 16686
      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.jeager.rule=Host(`jaeger.apps.cluster`)",
      ]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "jaeger-cassandra"
              local_bind_port  = "7000"
            }
          }
        }
      }


    }

    task "jaeger-query" {
      driver = "docker"
      config {
        image = "jaegertracing/jaeger-query:1.51"
        # see https://www.jaegertracing.io/docs/1.50/cli/#jaeger-query
        args = [
          "--cassandra.keyspace=jaeger_v1_dc1",
          "--cassandra.servers=localhost",
          "--cassandra.port=7000",
          "--log-level=debug"
        ]
      }
      resources {
        cpu    = 200
        memory = 100
      }
    }
  }

  group "casandra" {

    network {
      mode = "bridge"
    }

    service {
      name = "jaeger-cassandra"
      port = 7000
      connect {
        sidecar_service {}
      }
    }

    task "cassandra" {
      driver = "docker"
      config {
        image = "cassandra:4.0"
      }
    }

    task "cassandra-init" {
      driver = "docker"
      config {
        image = "jaegertracing/jaeger-cassandra-schema"
      }
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
    }
  }

}