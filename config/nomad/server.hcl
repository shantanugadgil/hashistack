datacenter = "dc1"
data_dir   = "/var/lib/nomad"

# if using more than 1 server, rename the node appropriately
name       = "srv1"

advertise {
  http = "0.0.0.0"
  rpc  = "{{ GetInterfaceIP \"eth0\" }}"
  serf = "{{ GetInterfaceIP \"eth0\" }}"
}

server {
  enabled          = true
  bootstrap_expect = 1
  encrypt          = "output of 'nomad operator keygen' here"

  server_join {
    retry_join = ["<ip_of_srv1_eth0>"]
  }
}
