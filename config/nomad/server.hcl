# 'eth0' should be your public interface
# for Vagrant based setups, you may need to replace "eth0" with "eth1"

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

  # count should be equal to the number of servers
  bootstrap_expect = 1
  encrypt          = "output of 'nomad operator keygen' here"

  server_join {
    retry_join = ["<public_ip_of_srv1_here>"]
  }
}
