#!/bin/bash

set -u
set -x

# check that the local Consul agent has joined the cluster
while (( 1 )); do

	http_ret=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8500/v1/status/leader)
	retval=$?

	if [[ "$retval" == "0" && "$http_ret" == "200" ]]; then
		echo "success ..."
		break
	fi

	echo "waiting for Consul agent to join the cluster ..."
	sleep 5
done

# induce delay to ease the "consul lock" contention if/when multiple
# nodes are created at the same time
delay=$(( $RANDOM % 10 + 3))
sleep $delay

if [[ -s /etc/stateful_id ]]; then
	id=$(cat /etc/stateful_id)

	echo "Machine seems to be already setup as part of a StatefulSet. ID [$id]."
	exit 0
fi

for (( index=1; index <= ${ASG_COUNT}; index++ )); do
    export ASG_INDEX="$index"
    consul lock -verbose -monitor-retry=10 -timeout=5s -child-exit-code ${ASG_NAME}/instance-${ASG_INDEX} bash config.bash
    ret=$?

    if (( $ret == 0 )); then
        echo "lock was acquired and config executed for [$ASG_INDEX] ..."
        break
    fi

    echo "unable to acquire lock for [$ASG_INDEX] (attempt ${index}/${ASG_COUNT}) ..."
    sleep 3
done

echo "Done [$0]"
