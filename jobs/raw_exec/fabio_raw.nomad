
job "fabio_raw" {
  datacenters = ["dc1"]
  type        = "system"

  constraint {
    attribute = node.class
    value     = "lb"
  }

  group "fabio" {
    task "fabio" {
      driver = "raw_exec"

      artifact {
        #source      = "https://github.com/fabiolb/fabio/releases/download/v1.5.11/fabio-1.5.11-go1.11.5-linux_amd64"
        source      = "http://some_local_web_server/fabio-1.5.11-go1.11.5-linux_amd64"
        mode        = "file"
        destination = "local/fabio"
      }

      config {
        command = "local/fabio"
      }

      resources {
        cpu    = 500
        memory = 256
        network {
          mbits = 20
          port "lb" {
            static = 9999
          }
          port "ui" {
            static = 9998
          }
        }
      }
    }
  }
}

