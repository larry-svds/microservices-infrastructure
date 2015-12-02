#!/usr/bin/env bash

# This is meant to perform an integration test for mantl, testing against many different providers
# destroying the infrastructure on each one when the test is completed. If any of the providers fail, the whole test
# fails. The test should be based on the sample files, since that is what we are providing for users.

## EXIT_CODE meanings:
## 00  success
## 01  docker_launch failed
## 10  terraform destroy failed
## 11  docker_launch and terraform destroy failed

EXIT_CODE=0 # passing until proven failed

## security setup
mkdir /ssh
ssh-keygen -t rsa -N '' -f /ssh/id_rsa
./security-setup

./docker_launch.sh || EXIT_CODE=$((EXIT_CODE+1))
terraform destroy -force -state=$TERRAFORM_STATE_ROOT/terraform.tfstate || EXIT_CODE=$((EXIT_CODE+10))
exit $EXIT_CODE
