job "foo_docker" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = node.class
    value     = "worker"
  }

  group "gowebhello" {
    count = 2
    network {
      port "http" {
        to = 8080
      }
    }

    task "gowebhello" {
      driver         = "docker"
      shutdown_delay = "10s"

      config {
        image = "udhos/web-scratch:0.7.1"
        ports = ["http"]
      }

      resources {
        cpu    = 500
        memory = 256
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
