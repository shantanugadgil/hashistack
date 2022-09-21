job "haproxy_docker" {
  region      = "global"
  datacenters = ["dc1"]

  #type        = "system"

  constraint {
    attribute = "${node.class}"
    value     = "lb"
  }
  update {
    stagger      = "10s"
    max_parallel = 1
  }
  group "lb" {
    count = 1
    network {
      port "http" {
        static = 80
      }
    }

    restart {
      interval = "10000s"
      attempts = 1000
      delay    = "10s"
      mode     = "delay"
    }

    task "haproxy" {
      driver         = "docker"
      shutdown_delay = "5s"

      config {
        image        = "haproxy:2.0.1-alpine"
        network_mode = "host"
        ports        = ["http"]

        volumes = [
          "custom/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg",
        ]
      }

      template {
        #source = "haproxy.cfg.tpl"
        data = <<EOH
global
  debug
  master-worker

defaults
  log global
  #grace 30s
  mode http
  option httplog
  option dontlognull
  timeout connect 5000
  timeout client 50000
  timeout server 50000

frontend http_front
  bind *:80
  stats uri /haproxy?stats
  stats enable
  stats show-node
  stats admin if TRUE
  default_backend http_back

backend http_back
  balance roundrobin
  cookie SERVERID insert indirect nocache{{range $i, $s := service "foo-docker"}}
  server {{.Node}}-{{.Address}}-{{.Port}} {{.Address}}:{{.Port}} cookie c{{$i}} check{{end}}
# eof
EOH

        #change_mode   = "signal"
        #change_signal = "SIGUSR2"

        destination = "custom/haproxy.cfg"
      }

      service {
        name = "haproxy"
        tags = ["global", "lb", "urlprefix-/haproxy"]
        port = "http"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 500 # 500 Mhz
        memory = 128 # 128MB
      }
    }
  }
}
