#!/bin/bash

# When this exits, exit all back ground process also.
trap 'kill $(jobs -p)' EXIT

# Die on error
set -e

# If long & short hostnames are not the same, use long hostnames
if ! [[ "$(hostname)" == "$(hostname -s)" ]]; then
    export RABBITMQ_USE_LONGNAME=true
fi

if ! [[ -z ${SSL_CERT_FILE+x} ]]; then
    use_ssl="yes"
    sed -i "s,CERTFILE,$SSL_CERT_FILE,g" ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config
fi

if ! [[ -z ${SSL_KEY_FILE+x} ]]; then
    use_ssl="yes"
    sed -i "s,KEYFILE,$SSL_KEY_FILE,g" ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config
fi

if ! [[ -z ${SSL_CA_FILE+x} ]]; then
    use_ssl="yes"
    sed -i "s,CAFILE,$SSL_CA_FILE,g" ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config
fi

if [[ "${use_ssl}" == "yes" ]]; then
    mkdir -p /opt || true
    # Create combined cert
    cat ${SSL_CERT_FILE} ${SSL_KEY_FILE} > /opt/combined.pem
    chmod 0400 /opt/combined.pem

    # More ENV vars for make clustering happiness
    # we don't handle clustering in this script, but these args should ensure
    # clustered SSL-enabled members will talk nicely
    export ERL_SSL_PATH="/usr/lib/erlang/lib/ssl-7.1/ebin"
    export RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-pa ${ERL_SSL_PATH} -proto_dist inet_tls -ssl_dist_opt server_certfile /opt/combined.pem -ssl_dist_opt server_secure_renegotiate true client_secure_renegotiate true"
    export RABBITMQ_CTL_ERL_ARGS="-pa ${ERL_SSL_PATH} -proto_dist inet_tls -ssl_dist_opt server_certfile /opt/combined.pem -ssl_dist_opt server_secure_renegotiate true client_secure_renegotiate true"

    echo "Launching RabbitMQ with SSL..."
    echo -e " - SSL_CERT_FILE: $SSL_CERT_FILE\n - SSL_KEY_FILE: $SSL_KEY_FILE\n - SSL_CA_FILE: $SSL_CA_FILE"
    cp ${RABBITMQ_HOME}/etc/rabbitmq/ssl.config \
        ${RABBITMQ_HOME}/etc/rabbitmq/rabbitmq.config
else
    echo "Launching RabbitMQ..."
    cp ${RABBITMQ_HOME}/etc/rabbitmq/standard.config \
        ${RABBITMQ_HOME}/etc/rabbitmq/rabbitmq.config
fi

# RMQ server process so we can tail the logs
# to the same stdout
${RABBITMQ_HOME}/sbin/rabbitmq-server &

# Capture the PID
rmq_pid=$!

if ! [[ -z ${RABBITMQ_DEFAULT_USER+x} ]]; then
    if ! [[ -z ${RABBITMQ_DEFAULT_PASS+x} ]]; then
        if ! [ -f "${RABBITMQ_HOME}/.administrator_exist" ]; then
            while [ "`${RABBITMQ_HOME}/sbin/rabbitmqctl status |grep rabbitmq_management |wc -l`" -ne "2" ]; do
                sleep 1
            done
            ${RABBITMQ_HOME}/sbin/rabbitmqctl delete_user guest
            ${RABBITMQ_HOME}/sbin/rabbitmqctl add_user ${RABBITMQ_DEFAULT_USER} ${RABBITMQ_DEFAULT_PASS}
            ${RABBITMQ_HOME}/sbin/rabbitmqctl set_user_tags ${RABBITMQ_DEFAULT_USER} administrator
            ${RABBITMQ_HOME}/sbin/rabbitmqctl set_permissions ${RABBITMQ_DEFAULT_USER} -p "/" ".*" ".*" ".*"
            touch ${RABBITMQ_HOME}/.administrator_exist
        fi
    fi
fi

# Tail the logs, but continue on to the wait command
echo -e "\n\nTailing log output:"
tail -F ${RABBITMQ_HOME}/var/log/rabbitmq/rabbit@${HOSTNAME}.log \
     -F ${RABBITMQ_HOME}/var/log/rabbitmq/rabbit@${HOSTNAME}-sasl.log &

# If RMQ dies, this script dies
wait $rmq_pid

