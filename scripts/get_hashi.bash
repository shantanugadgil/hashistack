#!/bin/bash

set -ue

software_name="$1"
software_version="$2"

# determine architecture
arch=$(uname -m)
case "${arch}" in
	'aarch64')
		software_arch="arm64"
		;;

	'x86_64')
		software_arch="amd64"
		;;
	*)
		echo "unsupported architecture [$arch]"
		exit 1
		;;
esac

case "${software_name}" in
	'nomad'|'consul'|'vault'|'terraform'|'packer')

		fname="${software_name}_${software_version}_linux_${software_arch}.zip"

		url="https://releases.hashicorp.com/${software_name}/${software_version}/${fname}"

		curl -Lf -o ${fname} ${url}

		unzip -o ${fname}

		;;
	*)
		echo "unupported software_name [${software_name}]"
		;;
esac

echo "Done"
