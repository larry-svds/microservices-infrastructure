#!/usr/bin/env bash

## This integration test assumes that ./terraform.yml and ./terraform.tf are already in place

EXIT_CODE=0 # passing until proven failed

## security setup
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
eval `ssh-agent -s` && ssh-add ~/.ssh/id_rsa
./security-setup

# this section needs to make fewer assumptions of the build env
# it currently makes an assumption that the build is in a docker container

## LOOP terraform's build step 3 times, to allow for terraform bugs to sort themselves out
terraform get
for i in `seq 1 3`
do
	terraform apply -state=$TERRAFORM_STATE_ROOT/terraform.tfstate
	APPLY_RETRY=$?
	if [ $APPLY_RETRY -eq 0 ]
	then
		break
	fi
done

if [ $APPLY_RETRY -ne 0 ] # if terraform fails three times, fail the test
then
	EXIT_CODE=1
fi

ansible-playbook playbooks/wait-for-hosts.yml --private-key ~/.ssh/id_rsa || EXIT_CODE=1
ansible-playbook terraform.yml --extra-vars=@security.yml --private-key ~/.ssh/id_rsa || EXIT_CODE=1

control_hosts=$(plugins/inventory/terraform.py --hostfile | awk '/control/ {print $1}')

testing/health-checks.py $control_hosts || EXIT_CODE=1

# DESTROY until terraforrm destroy exits with 0
DESTROY=1
while [ $DESTROY -ne 0 ]
do
	terraform destroy -force -state=$TERRAFORM_STATE_ROOT/terraform.tfstate
	DESTROY=$?
done
exit $EXIT_CODE
