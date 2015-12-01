#!/bin/bash

yum makecache
yum install -y gcc python-devel python-virtualenv libselinux-python
easy_install pip

cd /tmp
virtualenv env --system-site-packages
env/bin/pip install -r /vagrant/requirements.txt
source env/bin/activate

cd /vagrant

if [ ! -f /vagrant/security.yml ]; then
  ./security-setup --enable=false
fi

# Construct a valid inventory file
control_ip=$1
worker_ip=$2

# Add control and agent to hosts file
echo "$control_ip     control-01" >> /etc/hosts
echo "$worker_ip      worker-001" >> /etc/hosts

# echo this valid inventory to /vagrant/vagrant/vagrant-inventory
cat <<EOF > /vagrant/vagrant/vagrant-inventory
control-01   public_ipv4=$control_ip    private_ipv4=$control_ip
worker-001   public_ipv4=$worker_ip     private_ipv4=$worker_ip

[role=worker]
worker-001

[role=control]
control-01

[dc=vagrant]
control-01
worker-001

[role=control:vars]
consul_is_server=true

[dc=vagrant:vars]
ansible_ssh_user=vagrant
ansible_ssh_pass=vagrant
consul_dc=vagrant
provider=vagrant
EOF

ansible-playbook terraform.yml -e @security.yml -i /vagrant/vagrant/vagrant-inventory
