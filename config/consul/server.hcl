# 'eth0' should be your public interface
# for Vagrant based setups, you may need to replace "eth0" with "eth1"

bind_addr = "0.0.0.0"

advertise_addr = "{{ GetInterfaceIP \"eth0\" }}"

addresses {
  http = "0.0.0.0"
}

connect {
  enabled = true
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

# if using more than 1 server, rename the node appropriately
node_name = "@@NODE_NAME@@"

datacenter = "@@DATACENTER@@"

data_dir = "/var/lib/consul"

leave_on_terminate = true

skip_leave_on_interrupt = false

reconnect_timeout = "8h"

rejoin_after_leave = true

ui = true

server = true

bootstrap_expect = 1

retry_join = ["@@SRV_IP_ADDRESS@@"]

retry_max = 0
