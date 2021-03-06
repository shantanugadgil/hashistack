# 'eth0' should be your public interface
# for Vagrant based setups, you may need to replace "eth0" with "eth1"

bind_addr = "0.0.0.0"

datacenter = "dc1"

data_dir = "/var/lib/nomad"

# name the client appropriately; 'lb1', 'client1', 'client2', etc.
# based on the 'node_class'
name = "@@NODE_NAME@@"

disable_update_check = true

leave_on_interrupt = true

leave_on_terminate = true

#enable_syslog = true

log_file = "/var/log/nomad.log"

log_rotate_bytes = 10485760

log_rotate_max_files = 5

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

  #cpu_total_compute = @@CPU_TOTAL_COMPUTE@@

  network_interface = "eth0"
  server_join {
    retry_join = ["@@SRV_IP_ADDRESS@@"]
    retry_max  = 0
  }
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

plugin "docker" {
  config {
    auth {
      config = "/root/.docker/config.json"
      # Nomad will prepend "docker-credential-" to the helper value and call
      # that script name.
      helper = "ecr-login"
    }
    
    gc {
      image_delay = "12h"
    }
    
    volumes {
      enabled = true
    }
  }
}
