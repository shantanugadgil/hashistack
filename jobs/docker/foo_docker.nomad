job "foo_docker" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${node.class}"
    value     = "worker"
  }

  group "gowebhello" {
    count = 2

    task "gowebhello" {
      driver = "docker"

      config {
        image = "udhos/web-scratch:0.7.1"
        port_map {
          http = 8080
        }
      }

      resources {
        cpu    = 500
        memory = 256
        network {
          mbits = 10
          port "http" {}
        }
      }

      env {
        GWH_BANNER = "Welcome to FOO"
      }

      service {
        name = "foo-docker"
        tags = ["urlprefix-/foo"]
        port = "http"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}

