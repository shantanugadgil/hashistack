job "fabio_docker" {
  datacenters = ["dc1"]
  type        = "system"

  constraint {
    attribute = node.class
    value     = "lb"
  }

  group "fabio" {

    network {
      port "lb" {
        static = 9999
      }

      port "ui" {
        static = 9998
      }
    }

    task "fabio" {
      driver = "docker"

      config {
        image        = "fabiolb/fabio"
        network_mode = "host"
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}
