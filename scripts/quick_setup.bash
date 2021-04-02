#!/bin/bash

# vim: tabstop=4 expandtab shiftwidth=4 softtabstop=4

set -u
set -e

CONSUL_VERSION=${CONSUL_VERSION:-"1.9.4"}
NOMAD_VERSION=${NOMAD_VERSION:-"1.0.4"}
CNI_PLUGINS_VERSION=${CNI_PLUGINS_VERSION:-"0.9.1"}

consul_systemd_file="/etc/systemd/system/consul.service"
consul_upstart_file="/etc/init/consul.conf"

consul_config_dir="/etc/consul.d"
consul_server_config="${consul_config_dir}/server.hcl"
consul_client_config="${consul_config_dir}/client.hcl"

nomad_systemd_file="/etc/systemd/system/nomad.service"
nomad_upstart_file="/etc/init/nomad.conf"

nomad_config_dir="/etc/nomad.d"
nomad_common_config="${nomad_config_dir}/common.hcl"
nomad_server_config="${nomad_config_dir}/server.hcl"
nomad_client_config="${nomad_config_dir}/client.hcl"
nomad_vault_config="${nomad_config_dir}/vault.hcl"

log()
{
    local msg="$1"

    local dd=$(date +'%F %T')

    echo "[$dd] $msg"
    return 0
}

install_consul()
{
    # binary
    curl -L -o consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_${OS_ARCH}.zip
    unzip -o consul.zip
    chown root:root consul
    chmod 0755 consul
    mv -fv consul /usr/sbin/
    rm -fv consul.zip

    # service file
    case "$INIT_SYSTEM" in
        'systemd')
            curl -L -o ${consul_systemd_file} https://raw.githubusercontent.com/shantanugadgil/hashistack/master/systemd/consul.service
            chown root:root ${consul_systemd_file}
            chmod 0644 ${consul_systemd_file}
        ;;

        'upstart')
            curl -L -o ${consul_upstart_file} https://raw.githubusercontent.com/shantanugadgil/hashistack/master/upstart/consul.conf
            chown root:root ${consul_upstart_file}
            chmod 0644 ${consul_upstart_file}
            #initctl reload-configuration
            #telinit 2
        ;;
    esac

    return 0
}

configure_consul()
{
    local mode="$1"

    mkdir -p ${consul_config_dir}
    curl -L -o common.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/consul/common.hcl.j2?q=$RANDOM

    case "$mode" in
        'server'|'both')
            # TODO: make functions ...
            cat > server.json <<EOF
{
  "network_interface": "${NETWORK_INTERFACE}",
  "node_name": "${NODE_NAME}",
  "datacenter": "dc1",
  "server": true,
  "bootstrap_expect": 1,
  "consul_key": "${CONSUL_KEY}",
  "retry_join": "${SERVER_ADDRESS}"
}
EOF

            j2 common.hcl.j2 server.json >| ${consul_server_config}
            chmod 0644 ${consul_server_config}
        ;;

        'client')

            cat > client.json <<EOF
{
  "network_interface": "${NETWORK_INTERFACE}",
  "node_name": "${NODE_NAME}",
  "datacenter": "dc1",
  "server": false,
  "consul_key": "${CONSUL_KEY}",
  "retry_join": "${SERVER_ADDRESS}"
}
EOF

            j2 common.hcl.j2 client.json >| ${consul_client_config}
            chmod 0644 ${consul_client_config}
        ;;

    esac

    return 0
}

install_nomad()
{
    # binary
    curl -L -o nomad.zip https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_${OS_ARCH}.zip
    unzip -o nomad.zip
    chown root:root nomad
    chmod 0755 nomad
    mv -fv nomad /usr/sbin/
    rm -fv nomad.zip
    mkdir -p /var/lib/nomad
    chmod 0755 /var/lib/nomad

    # service file
    case "$INIT_SYSTEM" in
        'systemd')
            curl -L https://raw.githubusercontent.com/shantanugadgil/hashistack/master/systemd/nomad.service -o ${nomad_systemd_file}
            chown root:root ${nomad_systemd_file}
            chmod 0644 ${nomad_systemd_file}

            systemctl daemon-reload
            systemctl enable consul nomad
            #systemctl restart consul nomad
        ;;

        'upstart')
            curl -L https://raw.githubusercontent.com/shantanugadgil/hashistack/master/upstart/nomad.conf -o ${nomad_upstart_file}
            chown root:root ${nomad_upstart_file}
            chmod 0644 ${nomad_upstart_file}
            initctl reload-configuration
            telinit 2
        ;;
    esac
    return 0
}

configure_nomad()
{
    local mode="$1"

    mkdir -p ${nomad_config_dir}
    curl -L -o common.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/nomad/common.hcl.j2?q=$RANDOM
    curl -L -o client.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/nomad/client.hcl.j2?q=$RANDOM
    curl -L -o server.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/nomad/server.hcl.j2?q=$RANDOM

    cat > common..json <<EOF
{
  "network_interface": "${NETWORK_INTERFACE}",
  "node_name": "${NODE_NAME}",
  "datacenter": "dc1",
}
EOF

    cat > server.json <<EOF
{
  "network_interface": "${NETWORK_INTERFACE}",
  "node_name": "${NODE_NAME}",
  "datacenter": "dc1",
  "server": true,
  "bootstrap_expect": 1,
  "nomad_key": "${NOMAD_KEY}",
  "retry_join": "${SERVER_ADDRESS}"
}
EOF

    cat > client.json <<EOF
{
  "network_interface": "${NETWORK_INTERFACE}",
  "node_name": "${NODE_NAME}",
  "datacenter": "dc1",
  "server": false,
  "node_class": "${NODE_CLASS}",
  "cpu_total_compute": "${CPU_TOTAL_COMPUTE}",
  "retry_join": "${SERVER_ADDRESS}"
}
EOF

    j2 common.hcl.j2 common.json >| ${nomad_common_config}
    chmod 0644 ${nomad_common_config}

    case "$mode" in
        "server")
            j2 server.hcl.j2 server.json >| ${nomad_server_config}
            chmod 0644 ${nomad_server_config}
        ;;

        "client")
            j2 client.hcl.j2 server.json >| ${nomad_client_config}
            chmod 0644 ${nomad_server_config}
        ;;

        "both")
            j2 server.hcl.j2 server.json >| ${nomad_server_config}
            chmod 0644 ${nomad_server_config}

            j2 client.hcl.j2 server.json >| ${nomad_client_config}
            chmod 0644 ${nomad_server_config}

        ;;

        *)
            log "unsupported mode [$mode]"
            exit 1
        ;;
    esac

    chown root:root ${nomad_client_config}
    chmod 0644 ${nomad_client_config}

    return 0
}

configure_vault()
{
    if [[ "$VAULT_SERVER" == "" ]]; then
        return 0
    fi

    # client config
    mkdir -p ${nomad_config_dir}
    curl -L https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/nomad/vault.hcl -o ${nomad_vault_config}
    chown root:root ${nomad_vault_config}
    chmod 0644      ${nomad_vault_config}

    # update variables
    set -x
    sed -i "s/@@VAULT_SERVER@@/${VAULT_SERVER}/g" ${nomad_vault_config}
    set +x

    return 0
}

install_cni_plugins()
{
    curl -L -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-${OS_ARCH}-v${CNI_PLUGINS_VERSION}.tgz
    mkdir -p /opt/cni/bin
    tar -C /opt/cni/bin -xzf cni-plugins.tgz
    rm -fv cni-plugins.tgz

    cat > /etc/sysctl.d/90-consul-connect.conf <<EOF
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

    return 0
}

detect_root()
{
    local me=$(id -un)
    if [[ "$me" != "root" ]]; then
        log "ERROR: not running as root."
        exit 1
    fi

    log "INFO: running as root, all ok..."

    return 0
}

detect_init()
{
    # detect SystemD vs. Upstart
    ### FIXME: treat non-systemd as upstart (don't detect SysV Init)
    local one_exe=$(readlink -m /proc/1/exe)

    log "one_exe [$one_exe]"

    INIT_SYSTEM="none"

    case $one_exe in
        */systemd)
            INIT_SYSTEM='systemd'
            ;;
        *)
            INIT_SYSTEM='upstart'
            ;;
    esac

    log "INIT_SYSTEM [$INIT_SYSTEM]"

    return 0
}

detect_arch()
{
    local uname_m=$(uname -m)

    case "${uname_m}" in
        'x86_64')
            OS_ARCH="amd64"
            CPU_TOTAL_COMPUTE="auto"
            ;;
        'aarch64')
            OS_ARCH="arm64"

            current_speed=$(dmidecode -t 4 | grep 'Current Speed:' | awk '{print $3}')
            cpu_count=$(cat /proc/cpuinfo | grep 'processor' | wc -l)

            CPU_TOTAL_COMPUTE=$(( $current_speed * $cpu_count ))
            ;;
        *)
            log "***** UNSUPPORTED ARCHITECTURE *****"
            exit 1
            ;;
    esac

    return 0
}

parse_args()
{
    local install_type=""
    local server_address=""
    local consul_key=""
    local network_interface=""
    local vault_server=""
    local node_class=""

    # crude args parser
    while (( $# > 0 )); do

        case "$1" in
            '--install-type')
                install_type="$2"
                shift 2
                ;;

            '--server-address')
                server_address="$2"
                shift 2
                ;;

            '--consul-key')
                consul_key="$2"
                shift 2
                ;;

            '--network-interface')
                network_interface="$2"
                shift 2
                ;;

            '--vault-server')
                vault_server="$2"
                shift 2
                ;;

            '--node-class')
                node_class="$2"
                shift 2
                ;;

            '--nomad-key')
                nomad_key="$2"
                shift 2
                ;;

            *)
                log "unsupported option [$1]"
                exit 1
                ;;
        esac
    done

    # failure conditions ...
    if [[ "$install_type" == "" ]]; then
        log "install_type NOT defined"
        exit 1
    fi

    case "$install_type" in
        'server'|'client'|'both')
            log "INFO: setting up in [$install_type] mode ..."
            ;;

        *)
            log "invalid install_type [$install_type]"
            exit 1
            ;;
    esac
    INSTALL_TYPE="$install_type"

    if [[ "$server_address" == "" ]]; then
        log "server_address NOT defined"
        exit 1
    fi
    SERVER_ADDRESS="$server_address"

    if [[ "$consul_key" == "" ]]; then
        log "consul_key NOT defined"
        exit 1
    fi
    CONSUL_KEY="$consul_key"

    ###
    NETWORK_INTERFACE=${network_interface:-"default"}
    if [[ "$NETWORK_INTERFACE" == "" || "$NETWORK_INTERFACE" == "default" ]]; then
        NETWORK_INTERFACE=$(ip route show | grep '^default' | grep -o 'dev .*' | awk '{print $2}')
    fi

    log "NETWORK_INTERFACE [$NETWORK_INTERFACE]"

    case "$INSTALL_TYPE" in

        'client'|'both')

            ###
            if [[ "$node_class" == "" ]]; then
                log "node_class NOT defined"
                exit 1
            fi
            NODE_CLASS="$node_class"

            log "NODE_CLASS [$NODE_CLASS]"

            ###
            if [[ "$nomad_key" == "" ]]; then
                log "nomad_key NOT defined"
                exit 1
            fi
            NOMAD_KEY="$nomad_key"

            log "NOMAD_KEY [$NOMAD_KEY]"
        ;;
    esac

    ###
    VAULT_SERVER="${vault_server}"

    ###
    NODE_NAME=$(hostname -s)
    log "NODE_NAME [$NODE_NAME]"

    return 0
}

### script starts here ###
log "[$0] start"

detect_root

detect_init

detect_arch

parse_args "$@"

#install_consul
configure_consul ${INSTALL_TYPE}

#install_nomad
configure_nomad ${INSTALL_TYPE}

exit 0
configure_vault

install_cni_plugins
service consul restart
service nomad restart

log "[$0] done"
