bind_addr      = "0.0.0.0"
advertise_addr = "{{ GetInterfaceIP \"eth0\" }}"

addresses {
  http = "127.0.0.1 {{ GetInterfaceIP \"eth0\" }}"
}

encrypt        = "<same_key_as_the_server>"
node_name      = "client1"
datacenter     = "dc1"
data_dir       = "/var/lib/consul"

leave_on_terminate      = true
skip_leave_on_interrupt = true
rejoin_after_leave      = true
ui                      = true

server = false

retry_join = ["<ip_address_of_any_one_server>"]
