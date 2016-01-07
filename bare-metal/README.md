# Bare-Metal Mantl

By bare-metal we mean a set of physical computers that
have centos 7 installed on them.

If you are using open-stack, Vmware, or a cloud provider, Mantl.io has terraform scripts for
you. From a Mantl.io perspective, this doc is about setting up the inventory file
by hand and preparing the machines to a state similar to what terraform would have
done.

These scripts were created for set of 8 Intel NUCs. Each had 16GB of RAM
2 hyper threaded cores (I5s and I3s).  3 of them had 500 GB SSDs and 3
have 2 TB HDs.  Your hardware can vary.  Theses systems are 4 times larger
that the AWS systems defined in `terraform/aws.sample.tf` (m3.medium
instances have 1 core and 4GB RAM).  In other words, your machines could
be even smaller than our test system.   In fact, maybe you
have a couple of physical boxes, and then created a few virtual machine vms for the controls
on a couple of laptops.

This document explains how to prepare your machine with the base OS, network
hard drive concerns, creating your inventory and getting ansible ready.

## Setting Up Centos 7

### Thumb Drive Install

Create a boot Centos 7 http://www.myiphoneadventure.com/os-x/create-a-bootable-centos-usb-drive-with-a-mac-os-x
This can be a bit confusing and I used this as well. http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-mac-os
Mantl.io should start with the current Centos 7 minimum.


Once rebooted
No internet.. So I used http://www.krizna.com/centos/setup-network-centos-7/
First step get the interfaces with nmcli d
eno1 is ethernet

 * Alternative is to turn on the network when you do the install.
 * Create the centos user as an Admin
 * dont use the whole drive

### Set up Base Network

#### Chosing a static IP range

Why I chose 172.16.222.x

#### Give it a static IP and set DNS and Gateway

http://ask.xmodulo.com/configure-static-ip-address-centos7.html

edit `/etc/sysconfig/network-scripts/ifcfg-enp0s25`

These are the key lines.  BOOTPROTO and ONBOOT are probably already there.

        BOOTPROTO="static"
        IPADDR="172.16.222.6"
        GATEWAY="172.16.222.1"
        NETMASK="255.255.255.0"
        DNS1="8.8.8.8"
        DNS2="208.67.222.222"
        NM_CONTROLLED=no
        ONBOOT="yes"

the dns lines are going to have to change once consul is up.

NOTE: in centos 7 /etc/resolv.conf is a generated file.

You could also put the dns lines in /etc/sysconfig/network.

permanently change your host name with

http://www.server-world.info/en/note?os=CentOS_7&p=hostname

After saving then finally:

    systemctl restart network


### Create Partion For Docker LVM

    su
    parted /dev/sda print
    fdisk
    n
    default
    default
    +100G
    w
    reboot


don't put a file system on the partion

## Creating Your Inventory

    [role=control]
    control01 private_ipv4=172.16.222.6 ansible_ssh_host=172.16.222.6
    control02 private_ipv4=172.16.222.7 ansible_ssh_host=172.16.222.7
    control03 private_ipv4=172.16.222.8 ansible_ssh_host=172.16.222.8

    [role=worker]
    resource01 private_ipv4=172.16.222.11 ansible_ssh_host=172.16.222.11
    resource02 private_ipv4=172.16.222.12 ansible_ssh_host=172.16.222.12
    resource03 private_ipv4=172.16.222.13 ansible_ssh_host=172.16.222.13

    [role=edge]
    edge01 private_ipv4=172.16.222.16 ansible_ssh_host=172.16.222.16
    edge02 private_ipv4=172.16.222.17 ansible_ssh_host=172.16.222.17

    [dc=dc1]
    control01
    control02
    control03
    resource01
    resource02
    resource03
    edge01
    edge02

I had to add the ansible_ssh_host line to run `playbooks/reboot-hosts.yml`

the private_ipv4 is needed by several roles.

The dc=dc1 group is needed to set `consul_dc_group` in the consul roles. And is specifically usd in this setup in the
dnsmasq role.  Setting this in the inventory file is suggested by how the `vagrant\vagrant-inventory` is set.

## Getting Started with Ansible

Add the nodes to /etc/hosts

content is:

        127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
        ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
        172.16.222.5 LarryMac
        172.16.222.6 control01
        172.16.222.7 control02
        172.16.222.8 control03
        172.16.222.11 resource01
        172.16.222.12 resource02
        172.16.222.13 resource03
        172.16.222.16 edge01
        172.16.222.17 edge02

on LarryMac as lmurdock I created my id_rsa.  I created a authorized keys file with with content:

    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpsrVzeuTDjj/CRBYqKhBtPQiDbPtIipvy4b0vRcOZHUpaGWrWfDEm6g+PA+cwgsSx62FCGlBxuZ2Pm67sWO8yGtgQfS2sSxbfcmvEKD8HE9yex5Xqe0ABS5yCP9IfpQnNuI1Kw/tpNJ2cP+BtD836ZRrQip1Gx2lvJEOLwdzG6CER1Qb6rgMa2gbHWpgyGQLXA3UFjdC1Bfr8bW8ivUephKdL7Xy0yUzXcZDiPCb5zFWGrljwA8k4PEtebJqZPTOgLpiq+r3Uz+kEbzqS6Lr2WP0td+NFjhJQqvBJf9NifIdIjOBrqdhL1LqeZ94motSayhG0QY9dONDbbHOUzOtj lmurdock@Puck.local

Where puck is the mini and kafushery is my 17 macbook pro.

I then had to get this on all the machines, except Puck.. local

Create the .ssh directory

    ansible all -k -m file -a "dest=.ssh mode=700 owner=lmurdock state=directory"

the -k is needed cause I have to have it ask for a password at this point.

    ansible all -k -m copy -a "src=authorized_keys dest=.ssh/authorized_keys"

trouble is that the default umask is wrong and it won't use authorized_key file unless it is not writeable by anyone but lmurdock.  So..

    ansible all -k -m file -a "dest=.ssh/authorized_keys mode=644 owner=lmurdock"

I could have added the mode=644 to the copy command above but missed it.

now all commands can happen with out the password and -k option. Test with:

    ansible all -m ping


## Create Your bare-metal.yml


The entries below highlight the differences from terraform.sample.yml  please see the whole file at `bare-metal/bare-metal.yml`

Note that if you are comparing to an older terraform.sample.yml, glusterfs install is done seperately and not included in
`bare-metal\bare-metal.yml`


    - hosts: all
      vars:
        provider: bare-metal


    - hosts: role=worker
      vars:
        lvm_physical_device: /dev/sda4

    - hosts: role=control
      vars:
        lvm_physical_device: /dev/sda4
    - hosts: role=edge
      vars:
        lvm_physical_device: ""
        traefik_network_interface: enp1s0


## Run it.

ansible-playbook -u centos -K -i bare-metal/inventory -e @security.yml bare-metal/bare-metal.yml -v >& bare-metal/bare-metal.log

