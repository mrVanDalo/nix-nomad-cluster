job "whoami" {

  datacenters = ["dc1"]

  group "whoami" {
    count = 3

    network {
      mode = "bridge"
    }

    service {
      name = "whoami"
      port = 80

      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.whoami.rule=Host(`whoami.apps.cluster`)",
      ]

      connect {
        sidecar_service {}
      }

    }

    task "whoami" {
      env {
        WHOAMI_PORT_NUMBER = 80
      }
      driver = "docker"
      config {
        image = "traefik/whoami"
      }
    }
  }
}
