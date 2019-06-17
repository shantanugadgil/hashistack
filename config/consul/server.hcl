# 'eth0' should be your public interface
# for Vagrant based setups, you may need to replace "eth0" with "eth1"

bind_addr      = "0.0.0.0"
advertise_addr = "{{ GetInterfaceIP \"eth0\" }}"

addresses {
  http = "0.0.0.0"
}

encrypt        = "<output of 'consul keygen' here>"

# if using more than 1 server, rename the node appropriately
node_name      = "srv1"

datacenter     = "dc1"
data_dir       = "/var/lib/consul"

leave_on_terminate      = true
skip_leave_on_interrupt = true
rejoin_after_leave      = true
ui                      = true

server           = true
bootstrap_expect = 1

retry_join = ["<public_ip_of_srv1_here>"]
