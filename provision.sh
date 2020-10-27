#!/usr/bin/env bash
cores=2
cloud_init="/home/tcate/cloud-init/tcate-base.yaml"
disk=40GB
image=focal
memory=8GB
name=unset


while getopts c:ci:i:d:m:n: flag
do
  case "${flag}" in
    c) cores=${OPTARG};;
    ci) cloud_init=${OPTARG};;
    i) image=${OPTARG};;
    d) disk=${OPTARG};;
    m) memory=${OPTARG};;
    n) name=${OPTARG};;
  esac
done

if [[ "$name" == "unset" ]]; then
  echo "Must provide -n name of host to provision." 1>&2
  exit 1
fi

launch_output=$(multipass launch -c $cores -d $disk -m $memory -n $name --cloud-init $cloud_init $image 2>&1)

if [ $? -ne 0 ]
then
  echo $?
  echo $launch_output
  echo "Failed to provision"
  exit 1
fi

nodeip=$(multipass info $name --format json | jq .info.$name.ipv4[0] -r 2>&1)

if [ $? -ne 0 ]
then
  echo $nodeip
  echo "Failed to retrieve ip address for instance"
  exit 1
fi

echo "Attempting to provsion node at $nodeip"
ansible_output=$(ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$nodeip," playbooks/base/site.yml)
if [ $? -ne 0 ]
then
  echo $?
  echo "Failed to execute ansible-plabook against instance"
  exit 1
fi

echo "node $name ready at $nodeip"
exit 0
