datacenter = "dc1"
data_dir   = "/var/lib/nomad"

# name the client appropriately; 'lb1', 'client1', 'client2', etc.
# based on the 'node_class'
name       = "client1"

advertise {
  http = "{{ GetInterfaceIP \"eth0\" }}"
  rpc  = "{{ GetInterfaceIP \"eth0\" }}"
  serf = "{{ GetInterfaceIP \"eth0\" }}"
}

client {
  enabled           = true
  
  # the node class can be 'worker', 'lb'
  # NOTE: change the node 'name' (above) as per the 'node_class'
  node_class        = "worker"

  network_interface = "eth0"
  servers           = ["<list_of_ips_of_servers>"]
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}
