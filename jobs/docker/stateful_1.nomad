job "stateful_docker" {
  datacenters = ["dc1"]

  type        = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  constraint {
    attribute = "${node.class}"
    value     = "worker"
  }

  ############################################################

  group "group_1" {
    count = 1

    constraint {
      attribute = "${meta.statefulid}"
      value     = "1"
    }

    task "web" {
      driver         = "docker"
      shutdown_delay = "10s"

      config {
        image = "shantanug/gowebhello:0.2"

        port_map {
          http = 8080
        }
      }

      resources {
        cpu    = 500
        memory = 256

        network {
          mbits = 10
          port  "http"{}
        }
      }

      env {
        GWH_BANNER = "WELCOME TO STATEFUL GROUP 1."
      }

      service {
        name = "stateful1"
        tags = ["urlprefix-/stateful1"]
        port = "http"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      } # service
    } # task web
  } # group group_1

  ############################################################

  group "group_2" {
    count = 1

    constraint {
      attribute = "${meta.statefulid}"
      value     = "2"
    }

    task "web" {
      driver         = "docker"
      shutdown_delay = "10s"

      config {
        image = "shantanug/gowebhello:0.2"

        port_map {
          http = 8080
        }
      }

      resources {
        cpu    = 500
        memory = 256

        network {
          mbits = 10
          port  "http"{}
        }
      }

      env {
        GWH_BANNER = "WELCOME TO STATEFUL GROUP 2."
      }

      service {
        name = "stateful2"
        tags = ["urlprefix-/stateful2"]
        port = "http"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      } # service
    } # task web
  } # group group_2

  ############################################################

  group "group_3" {
    count = 1

    constraint {
      attribute = "${meta.statefulid}"
      value     = "3"
    }

    task "web" {
      driver         = "docker"
      shutdown_delay = "10s"

      config {
        image = "shantanug/gowebhello:0.2"

        port_map {
          http = 8080
        }
      }

      resources {
        cpu    = 500
        memory = 256

        network {
          mbits = 10
          port  "http"{}
        }
      }

      env {
        GWH_BANNER = "WELCOME TO STATEFUL GROUP 3."
      }

      service {
        name = "stateful3"
        tags = ["urlprefix-/stateful3"]
        port = "http"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      } # service
    } # task web
  } # group group_3
} # job
