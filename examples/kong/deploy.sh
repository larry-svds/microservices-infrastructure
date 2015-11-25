#!/bin/bash
set -e pipefail

ip=0.0.0.0
# User for Marathon server (default: admin)"
username=youruser
# Password for Marathon server (see 'nginx_admin_password' in security.yml)
password=yourpass

# Run an Ansible playbook that just deploys kong.yml configuration to all nodes
# at /etc/kong/kong.yml
ansible-playbook main.yml -e @../../security.yml -e "ansible_python_interpreter=/usr/bin/python2" -i ../../plugins/inventory/terraform.py

# Install the Cassandra mesos framework via mantl-api
# Consul service: cassandra-mantl-node.service.consul:7000
# Marathon ID: /cassandra/mantl
curl -sku "$username:$password" -X POST -H "Content-Type: application/json" -d '{"name": "cassandra"}' https://$ip/api/1/packages

# Wait for Cassandra service to become available in Consul
while ! curl -sku "$username:$username" -X GET https://$ip:8500/v1/catalog/services|grep -q cassandra; do
  echo "Waiting for Cassandra to become available..."
  sleep 1
done

# Post the kong.json app description to Marathon
curl -sku "$username:$password" -X POST -H "Content-Type: application/json" -d @kong.json https://$ip/marathon/v2/apps
