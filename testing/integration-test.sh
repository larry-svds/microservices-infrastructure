#!/usr/bin/env bash

## This integration test assumes that ./terraform.yml and ./terraform.tf are already in place

EXIT_CODE=0 # passing until proven failed

## security setup
mkdir /ssh
ssh-keygen -t rsa -N '' -f /ssh/id_rsa
./security-setup

./docker_launch.sh || EXIT_CODE=1
terraform destroy -force -state=$TERRAFORM_STATE_ROOT/terraform.tfstate || EXIT_CODE=1
exit $EXIT_CODE
