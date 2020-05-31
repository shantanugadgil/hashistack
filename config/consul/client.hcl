# 'eth0' should be your public interface
# for Vagrant based setups, you may need to replace "eth0" with "eth1"

bind_addr = "0.0.0.0"

advertise_addr = "{{ GetInterfaceIP \"eth0\" }}"

addresses {
  http = "127.0.0.1 {{ GetInterfaceIP \"eth0\" }}"
}

ports {
  grpc = 8502
  dns  = -1
}

disable_host_node_id = true

disable_update_check = true

enable_script_checks = true

#enable_syslog = true

log_level = "INFO"

log_file = "/var/log/consul.log"

log_rotate_bytes = 10485760

log_rotate_max_files = 5

protocol = 3

raft_protocol = 3

encrypt = "@@CONSUL_KEY@@"

# name the clients appropriately; 'lb1', 'client1', 'client2', etc.
node_name = "@@NODE_NAME@@"

datacenter = "dc1"

data_dir = "/var/lib/consul"

leave_on_terminate = true

# keep this 'false' for clients
skip_leave_on_interrupt = false

rejoin_after_leave = true

ui = true

server = false

retry_join = ["@@SRV_IP_ADDRESS@@"]

retry_max = 0
