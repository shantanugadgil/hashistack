#!/bin/bash

set -u
set -x

exec 1>> /tmp/volume_mounter.log 2>&1

region=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

instance_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)

echo "ASG_INDEX [$ASG_INDEX]"
echo "DEVICE_PATH [$DEVICE_PATH]"
echo "instance [$instance_id]"

volume_id=$(aws --region $region ec2 describe-volumes --filters --filters Name=tag:Name,Values=worker-$ASG_INDEX | jq -r '.Volumes[].VolumeId')

echo "volume [$volume_id]"

# TODO: wait for volume to be available 
while (( 1 )); do
    volume_state=$(aws --region $region ec2 describe-volumes --volume-ids $volume_id --query 'Volumes[0].State' --output text)

    if [[ "$volume_state" == "available" ]]; then
        break
    fi

    echo "volume_state [$volume_state]"
    sleep 30
done

aws --region $region ec2 attach-volume --volume-id $volume_id --instance-id $instance_id --device $DEVICE_PATH
sleep 10

mkdir -p /data

blkid $DEVICE_PATH
ret=$?

if (( $ret != 0 )); then
        mkfs.ext4 $DEVICE_PATH
fi

mount -v $DEVICE_PATH /data

dd=$(date)
echo "[$dd] mount and startup message" >> /data/log.txt

echo "Done"
