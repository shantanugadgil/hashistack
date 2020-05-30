# 'eth0' should be your public interface
# for Vagrant based setups, you may need to replace "eth0" with "eth1"

bind_addr = "0.0.0.0"

datacenter = "dc1"

data_dir = "/var/lib/nomad"

# name the client appropriately; 'lb1', 'client1', 'client2', etc.
# based on the 'node_class'
name = "@@NODE_NAME@@"

disable_update_check = true

addresses {
  http = "{{ GetInterfaceIP \"eth0\" }}"
}

advertise {
  http = "{{ GetInterfaceIP \"eth0\" }}"
  rpc  = "{{ GetInterfaceIP \"eth0\" }}"
  serf = "{{ GetInterfaceIP \"eth0\" }}"
}

client {
  enabled = true

  # the node class can be 'worker', 'lb'
  # NOTE: change the node 'name' (above) as per the 'node_class'
  node_class = "@@NODE_CLASS@@"

  network_interface = "eth0"
  server_join {
    retry_join = ["@@SRV_IP_ADDRESS@@"]
  }
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}
