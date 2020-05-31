# 'eth0' should be your public interface
# for Vagrant based setups, you may need to replace "eth0" with "eth1"

bind_addr = "0.0.0.0"

datacenter = "dc1"

data_dir = "/var/lib/nomad"

# if using more than 1 server, rename the node appropriately
name = "@@NODE_NAME@@"

disable_update_check = true

leave_on_interrupt = true

leave_on_terminate = true

#enable_syslog = true

log_file = "/var/log/nomad.log"

log_rotate_bytes = 10485760

log_rotate_max_files = 5

addresses {
  http = "0.0.0.0"
}

advertise {
  http = "{{ GetInterfaceIP \"eth0\" }}"
  rpc  = "{{ GetInterfaceIP \"eth0\" }}"
  serf = "{{ GetInterfaceIP \"eth0\" }}"
}

server {
  enabled = true

  # count should be equal to the number of servers
  bootstrap_expect = 1
  encrypt          = "@@NOMAD_KEY@@"

  server_join {
    retry_join = ["@@SRV_IP_ADDRESS@@"]
    retry_max = 0
  }
}
