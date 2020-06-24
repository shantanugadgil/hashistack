ui = true

cluster_name = "vault-dc1"

#storage "consul" {
#  address = "127.0.0.1:8500"
#  path    = "vault"
#}

storage "raft" {
  path    = "/var/lib/vault"
  node_id = "vault-server-1"
}

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = true
}

disable_mlock = true
api_addr = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"
