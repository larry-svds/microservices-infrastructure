#!/usr/bin/env bash

## This integration test assumes that ./terraform.yml and ./terraform.tf are already in place

EXIT_CODE=0 # passing until proven failed

## security setup
mkdir /ssh
ssh-keygen -t rsa -N '' -f /ssh/id_rsa
./security-setup

# this section needs to make fewer assumptions of the build env
# it currently makes an assumption that the build is in a docker container

## LOOP terraform's build step 3 times, to allow for terraform bugs to sort themselves out
./docker_launch.sh || EXIT_CODE=1

control_hosts=$(plugins/inventory/terrform.py --hostfile | awk '/control/ {print $1}')

testing/health-checks.py $control_hosts || EXIT_CODE=1
terraform destroy -force -state=$TERRAFORM_STATE_ROOT/terraform.tfstate || EXIT_CODE=1
exit $EXIT_CODE
