job "bar_raw" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${node.class}"
    value     = "worker"
  }

  group "gowebhello" {
    count = 1

    task "gowebhello" {
      driver = "raw_exec"

      artifact {
        #source = "https://github.com/udhos/gowebhello/releases/download/v0.6/gowebhello_linux_amd64"
        source      = "http://10.20.13.80:8080/www/gowebhello_linux_amd64"
        mode        = "file"
        destination = "local/gowebhello"
      }

      config {
        command = "local/gowebhello"
      }

      resources {
        cpu    = 500
        memory = 256
        network {
          mbits = 10
          port "http" { static = "8080" }
        }
      }

      env {
        GWH_BANNER = "Welcome to BAR"
      }

      service {
        name = "bar-raw"
        tags = ["urlprefix-/bar"]
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

