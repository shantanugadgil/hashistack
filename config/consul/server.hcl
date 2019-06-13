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

retry_join = ["<ip_of_srv1_eth0_here>"]
