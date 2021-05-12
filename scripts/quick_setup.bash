#!/bin/bash

# vim: tabstop=4 expandtab shiftwidth=4 softtabstop=4

set -u
set -e

###############################################################################
CONSUL_VERSION=${CONSUL_VERSION:-"1.9.5"}

consul_config_dir="/etc/consul.d"
consul_server_config="${consul_config_dir}/server.hcl"
consul_client_config="${consul_config_dir}/client.hcl"

consul_systemd_file="/etc/systemd/system/consul.service"
consul_upstart_file="/etc/init/consul.conf"

###############################################################################
NOMAD_VERSION=${NOMAD_VERSION:-"1.1.0-beta1"}

nomad_config_dir="/etc/nomad.d"
nomad_common_config="${nomad_config_dir}/common.hcl"
nomad_server_config="${nomad_config_dir}/server.hcl"
nomad_client_config="${nomad_config_dir}/client.hcl"
nomad_vault_config="${nomad_config_dir}/vault.hcl"

nomad_systemd_file="/etc/systemd/system/nomad.service"
nomad_upstart_file="/etc/init/nomad.conf"

###############################################################################
VAULT_VERSION=${VAULT_VERSION:-"1.7.1"}

vault_config_dir="/etc/vault.d"
vault_server_config="${vault_config_dir}/server.hcl"
#vault_client_config="${vault_config_dir}/client.hcl"

vault_systemd_file="/etc/systemd/system/vault.service"
vault_upstart_file="/etc/init/vault.conf"

###############################################################################
CNI_PLUGINS_VERSION=${CNI_PLUGINS_VERSION:-"0.9.1"}

###############################################################################

__log ()
{
    local msgframe="$1"
    local msgtype="$2"
    local msgcontent="$3"

    local curtime=$(date +"%F %T")
    local stack=($(caller $msgframe))

    echo "[$curtime] [${stack[1]}] $msgtype: $msgcontent" >&2
}

###############################################################################

log_fatal()
{
    local msg="$@"

    __log 1 "ERROR" "$msg"

    exit 1
}

###############################################################################

log_error()
{
    local msg="$@"

    __log 1 "ERROR" "$msg"
    
    return 0
}

###############################################################################

log_debug()
{
    local msg="$@"

    __log 1 "DEBUG" "$msg"

    return 0
}

###############################################################################

log_warn()
{
    local msg="$@"

    __log 1 "WARN" "$msg"

    return 0
}

###############################################################################

log_info()
{
    local msg="$@"

    __log 1 "INFO" "$msg"

    return 0
}

###############################################################################

install_consul()
{
    log_debug "start"

    # binary
    curl -L -f -o consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_${OS_ARCH}.zip
    unzip -o consul.zip
    chown root:root consul
    chmod 0755 consul
    mv -fv consul /usr/sbin/
    rm -fv consul.zip

    # service file
    case "$INIT_SYSTEM" in
        'systemd')
            curl -L -f -o ${consul_systemd_file} https://raw.githubusercontent.com/shantanugadgil/hashistack/master/systemd/consul.service
            chown root:root ${consul_systemd_file}
            chmod 0644 ${consul_systemd_file}

            systemctl daemon-reload
            systemctl enable consul
        ;;

        'upstart')
            curl -L -f -o ${consul_upstart_file} https://raw.githubusercontent.com/shantanugadgil/hashistack/master/upstart/consul.conf
            chown root:root ${consul_upstart_file}
            chmod 0644 ${consul_upstart_file}
            #initctl reload-configuration
            #telinit 2
        ;;
    esac

    log_debug "end"
    return 0
}

__configure_consul_server()
{
    log_debug "start"

    curl -L -f -o common.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/consul/common.hcl.j2?${RANDOM}

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
    chown root:root ${consul_server_config}
    chmod 0644 ${consul_server_config}

    log_debug "end"
    return 0
}

__configure_consul_client()
{
    log_debug "start"

    curl -L -f -o common.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/consul/common.hcl.j2?${RANDOM}

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
    chown root:root ${consul_client_config}
    chmod 0644 ${consul_client_config}

    log_debug "end"
    return 0
}

configure_consul()
{
    log_debug "start"

    local mode="$1"

    mkdir -p ${consul_config_dir}

    case "$mode" in
        'server'|'both')
            __configure_consul_server
        ;;

        'client')
            __configure_consul_client
        ;;

        *)
            log_info "ERROR: unsupported mode [$mode]"
            exit 1
        ;;
    esac

    log_debug "end"
    return 0
}

install_nomad()
{
    log_debug "start"

    # binary
    curl -L -f -o nomad.zip https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_${OS_ARCH}.zip
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
            curl -L -f -o ${nomad_systemd_file} https://raw.githubusercontent.com/shantanugadgil/hashistack/master/systemd/nomad.service
            chown root:root ${nomad_systemd_file}
            chmod 0644 ${nomad_systemd_file}

            systemctl daemon-reload
            systemctl enable nomad
        ;;

        'upstart')
            curl -L -f -o ${nomad_upstart_file} https://raw.githubusercontent.com/shantanugadgil/hashistack/master/upstart/nomad.conf
            chown root:root ${nomad_upstart_file}
            chmod 0644 ${nomad_upstart_file}
            initctl reload-configuration
            telinit 2
        ;;
    esac

    log_debug "end"
    return 0
}

__configure_nomad_common()
{
    log_debug "start"

    curl -L -f -o common.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/nomad/common.hcl.j2?${RANDOM}

    cat > common.json <<EOF
{
  "network_interface": "${NETWORK_INTERFACE}",
  "node_name": "${NODE_NAME}",
  "datacenter": "dc1"
}
EOF

    j2 common.hcl.j2 common.json >| ${nomad_common_config}
    chown root:root ${nomad_common_config}
    chmod 0644 ${nomad_common_config}

    log_debug "end"
    return 0
}

__configure_nomad_server()
{
    log_debug "start"

    curl -L -f -o server.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/nomad/server.hcl.j2?${RANDOM}

    cat > server.json <<EOF
{
  "bootstrap_expect": 1,
  "nomad_key": "${NOMAD_KEY}",
  "retry_join": "${SERVER_ADDRESS}"
}
EOF

    j2 server.hcl.j2 server.json >| ${nomad_server_config}
    chown root:root ${nomad_server_config}
    chmod 0644 ${nomad_server_config}

    log_debug "end"
    return 0
}

__configure_nomad_client()
{
    log_debug "start"

    curl -L -f -o client.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/nomad/client.hcl.j2?${RANDOM}

    cat > client.json <<EOF
{
  "node_class": "${NODE_CLASS}",
  "cpu_total_compute": "${CPU_TOTAL_COMPUTE}",
  "network_interface": "${NETWORK_INTERFACE}",
  "retry_join": "${SERVER_ADDRESS}"
}
EOF

    j2 client.hcl.j2 client.json >| ${nomad_client_config}
    chown root:root ${nomad_client_config}
    chmod 0644 ${nomad_client_config}

    log_debug "end"
    return 0
}

__configure_nomad_vault()
{
    log_debug "start"

    curl -L -f -o vault.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/nomad/vault.hcl.j2?${RANDOM}

    cat > vault.json <<EOF
{
  "mode": "${MODE}",
  "vault_server": "${VAULT_SERVER}",
  "vault_token": "undefined"
}
EOF

    j2 vault.hcl.j2 vault.json >| ${nomad_vault_config}
    chown root:root ${nomad_vault_config}
    chmod 0644 ${nomad_vault_config}
    
    log_debug "end"
    return 0
}

configure_nomad()
{
    log_debug "start"

    local mode="$1"

    # for Vault configuration
    MODE="${mode}"

    mkdir -p ${nomad_config_dir}

    __configure_nomad_common
    __configure_nomad_vault

    case "$mode" in
        "server")
            __configure_nomad_server
        ;;

        "client")
            __configure_nomad_client
        ;;

        "both")
            __configure_nomad_server
            __configure_nomad_client
        ;;

        *)
            log_fatal "unsupported mode [$mode]"
        ;;
    esac

    log_debug "end"
    return 0
}

install_vault()
{
    log_debug "start"

    # binary
    curl -L -f -o vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${OS_ARCH}.zip
    unzip -o vault.zip
    chown root:root vault
    chmod 0755 vault
    mv -fv vault /usr/sbin/
    rm -fv vault.zip
    mkdir -p /var/lib/vault
    chmod 0755 /var/lib/vault

    # service file
    case "$INIT_SYSTEM" in
        'systemd')
            curl -L -f -o ${vault_systemd_file} https://raw.githubusercontent.com/shantanugadgil/hashistack/master/systemd/vault.service
            chown root:root ${vault_systemd_file}
            chmod 0644 ${vault_systemd_file}

            systemctl daemon-reload
            systemctl enable vault
        ;;

        'upstart')
            curl -L -f -o ${vault_upstart_file} https://raw.githubusercontent.com/shantanugadgil/hashistack/master/upstart/vault.conf
            chown root:root ${vault_upstart_file}
            chmod 0644 ${vault_upstart_file}
            initctl reload-configuration
            telinit 2
        ;;
    esac

    log_debug "end"
    return 0
}

__configure_vault_server()
{
    log_debug "start"

    curl -L -f -o server.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/vault/server.hcl.j2?${RANDOM}

    cat > server.json <<EOF
{
  "cluster_name": "${CLUSTER_NAME}",
  "node_name": "${NODE_NAME}",
  "server_address": "${SERVER_ADDRESS}",
  "storage": "${STORAGE}",
  "seal": "default"
}
EOF

    j2 server.hcl.j2 server.json >| ${vault_server_config}
    chown root:root ${vault_server_config}
    chmod 0644 ${vault_server_config}

    log_debug "end"
    return 0
}

__configure_vault_client()
{
    log_debug "start"

    log_fatal "NOT IMPLEMENTED YET"

    curl -L -f -o client.hcl.j2 https://raw.githubusercontent.com/shantanugadgil/hashistack/master/config/vault/client.hcl.j2?${RANDOM}

    cat > client.json <<EOF
{
  "cluster_name": "${CLUSTER_NAME}",
  "node_name": "${NODE_NAME}",
  "network_interface": "${NETWORK_INTERFACE}",
  "retry_join": "${SERVER_ADDRESS}"
}
EOF

    j2 client.hcl.j2 client.json >| ${vault_client_config}
    chown root:root ${vault_client_config}
    chmod 0644 ${vault_client_config}

    log_debug "end"
    return 0
}


configure_vault()
{
    log_debug "start"

    local mode="$1"

    mkdir -p ${vault_config_dir}

    case "$mode" in
        'server')
            __configure_vault_server
        ;;

        'client')
            __configure_vault_client
        ;;

        *)
            log_info "ERROR: unsupported mode [$mode]"
            exit 1
        ;;
    esac

    log_debug "end"
    return 0
}


install_cniplugins()
{
    log_debug "start"

    curl -L -f -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-${OS_ARCH}-v${CNI_PLUGINS_VERSION}.tgz
    mkdir -p /opt/cni/bin
    tar -C /opt/cni/bin -xzf cni-plugins.tgz
    rm -fv cni-plugins.tgz

    cat > /etc/sysctl.d/90-consul-connect.conf <<EOF
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

    log_debug "end"
    return 0
}

detect_root()
{
    log_debug "start"

    local me=$(id -un)
    if [[ "$me" != "root" ]]; then
        log_fatal "not running as root."
    fi

    log_info "running as root, all ok..."

    log_debug "end"
    return 0
}

detect_init()
{
    log_debug "start"

    # detect SystemD vs. Upstart
    ### FIXME: treat non-systemd as upstart (don't detect SysV Init)
    local exe_one=$(readlink -m /proc/1/exe)

    log_info "exe_one [$exe_one]"

    INIT_SYSTEM="none"

    case ${exe_one} in
        */systemd)
            INIT_SYSTEM='systemd'
            ;;
        *)
            INIT_SYSTEM='upstart'
            ;;
    esac

    log_info "INIT_SYSTEM [$INIT_SYSTEM]"

    log_debug "end"
    return 0
}

detect_arch()
{
    log_debug "start"

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
            log_fatal "unsupported architecture [$uname_m]"
            exit 1
            ;;
    esac

    log_info "OS_ARCH [$OS_ARCH]"

    log_debug "end"
    return 0
}

check_if_defined()
{
    local param="$1"
    local value="$2"

    if [[ "$value" == "" ]]; then
        log_fatal "required parameter [$param] is not defined"
    fi

    return 0
}

check_combination()
{
    local component="$1"
    local mode="$2"
    local ok=0

    case "${component}" in
        'consul')
            case "$mode" in
                'server'|'client')
                    ok=1
                ;;
            esac
        ;;

        'nomad')
            case "$mode" in
                'client'|'server'|'both')
                    ok=1
                ;;
            esac
        ;;

        'vault')
            case "${mode}" in
                'server')
                    ok=1
                ;;
            esac
        ;;

        'cniplugins')
            case "$mode" in
                'client'|'both')
                    ok=1
                ;;
            esac
        ;;
    esac

    if (( $ok == 0 )); then
        log_fatal "unsupported combination of component [$component] and mode [$mode]"
    fi

    return 0
}

parse_args()
{
    log_debug "start"

    local action=""
    local component=""
    local mode=""
    local server_address=""
    local consul_key=""
    local network_interface=""
    local vault_server=""
    local node_class=""
    local nomad_key=""
    local storage=""
    local cluster_name=""

    # crude args parser
    while (( $# > 0 )); do

        case "$1" in
            '--action')
                action="$2"
                shift 2
                ;;

            '--component')
                component="$2"
                shift 2
                ;;

            '--mode')
                mode="$2"
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

            '--storage')
                storage="$2"
                shift 2
                ;;

            '--cluster-name')
                cluster_name="$2"
                shift 2
                ;;

            *)
                log_fatal "unsupported option [$1]"
                ;;
        esac
    done

    #####
    check_if_defined "action" "$action"
    case "$action" in
        'install'|'configure') ok=1; ;;

        *)
            log_fatal "invalid action [$action]"
        ;;
    esac
    ACTION="$action"
    log_info "ACTION [$ACTION]"

    #####
    check_if_defined "component" "$component"
    case "$component" in
        'consul'|'nomad'|'vault'|'cniplugins') ok=1; ;;

        *)
            log_fatal "invalid component [$component]"
        ;;
    esac
    COMPONENT="$component"
    log_info "COMPONENT [$COMPONENT]"

    ###
    NODE_NAME=$(hostname -s)
    log_info "NODE_NAME [$NODE_NAME]"

    #####
    case "$action" in
        'install')
            install_${component} "${mode}"
        ;;

        'configure')
            #####
            check_if_defined "mode" "$mode"
            MODE="$mode"
            log_info "MODE [$MODE]"

            check_combination "${component}" "${mode}"

            #####
            NETWORK_INTERFACE="${network_interface}"
            case "${network_interface}" in
                ''|'default')
                    NETWORK_INTERFACE=$(ip route show | grep '^default' | grep -o 'dev .*' | awk '{print $2}')
                ;;
            esac
            log_info "NETWORK_INTERFACE [$NETWORK_INTERFACE]"

            #####
            SERVER_ADDRESS="${server_address}"
            case "${server_address}" in
                'default'|'')
                    SERVER_ADDRESS=$(ip -o -4 addr list $NETWORK_INTERFACE | head -n1 | awk '{print $4}' | cut -d/ -f1)
                ;;
            esac
            log_info "SERVER_ADDRESS [$SERVER_ADDRESS]"

            #####
            case "${component}" in
                'vault')
                    check_if_defined "cluster_name" "$cluster_name"
                    CLUSTER_NAME="$cluster_name"
                    log_info "CLUSTER_NAME [$CLUSTER_NAME]"
                    
                    check_if_defined "storage" "$storage"
                    STORAGE="$storage"
                    log_info "STORAGE [$STORAGE]"
                ;;

                'consul')
                    #####
                    check_if_defined "consul_key" "$consul_key"
                    CONSUL_KEY="$consul_key"
                    log_info "CONSUL_KEY [$CONSUL_KEY]"

                    case "${mode}" in
                        'client')
                            check_if_defined "server_address" "$server_address"
                        ;;
                    esac
                ;;

                'nomad')
                    ###
                    VAULT_SERVER="${vault_server}"
                    log_info "VAULT_SERVER [$VAULT_SERVER]"

                    case "${mode}" in
                        'server')
                            #####
                            check_if_defined "nomad_key" "$nomad_key"
                            NOMAD_KEY="$nomad_key"
                            log_info "NOMAD_KEY [$NOMAD_KEY]"
                        ;;
                    esac

                    case "${mode}" in
                        'client'|'both')
                            #####
                            check_if_defined "node_class" "$node_class"
                            NODE_CLASS="$node_class"
                            log_info "NODE_CLASS [$NODE_CLASS]"
                        ;;
                    esac

                    case "${mode}" in
                        'client')
                            check_if_defined "server_address" "$server_address"
                        ;;
                    esac
                ;;

                *)
                    log_fatal "unsupported component [$component]"
                ;;
            esac

            #####
            configure_${component} "${mode}"
        ;;
    esac

    log_debug "end"
    return 0
}

### script starts here ###
log_info "[$0] start"

detect_root

detect_init

detect_arch

parse_args "$@"

# service "enabled" during install, restart it here
if [[ "$ACTION" == "configure" ]]; then
    log_info "restarting [$COMPONENT] service ..."
    service ${COMPONENT} restart
fi

log_info "[$0] done"
exit 0
