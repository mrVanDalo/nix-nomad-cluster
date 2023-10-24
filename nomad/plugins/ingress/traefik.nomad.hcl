job "traefik" {

  region      = "global"
  datacenters = ["dc1"]
  type        = "system"

  group "traefik" {

    network {
      port "http" {
        static = 8080
      }

      port "api" {
        static = 8081
      }
    }

    service {
      name = "traefik"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.traefik-public.rule=Host(`traefik.nomad`)",
        "traefik.http.routers.traefik-public.service=api@internal",
        #"traefik.http.routers.traefik-public.middlewares=admin-auth",
        #"traefik.http.middlewares.admin-auth.basicauth.users=admin:admin",
      ]

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.10.4"
        network_mode = "host"

        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml",
        ]
      }

      template {
        data = <<EOF
entryPoints:
  http:
    address: ":8080"
    forwardedHeaders:
      trustedIPs:
        - 10.0.0.2
api:
  dashboard: true
log:
  level: INFO
accessLog: {}

providers:
  consulCatalog:
    prefix: "traefik"
    connectAware: true
    exposedByDefault: false
    endpoint:
      address: "127.0.0.1:8500"
      scheme: "http"
EOF

        destination = "local/traefik.yaml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
