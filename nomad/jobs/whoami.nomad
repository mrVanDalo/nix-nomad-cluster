job "whoami" {

  datacenters = ["dc1"]

  group "whoami" {
    count = 1

    network {
      mode = "bridge"
    }

    service {
      name = "whoami-demo"
      port = 80

      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.http.rule=Host(`app.nomad`)",
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
