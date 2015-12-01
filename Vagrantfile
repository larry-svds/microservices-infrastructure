# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

def load_security
  fname = File.join(File.dirname(__FILE__), "security.yml")
  if !File.exist? fname
    $stderr.puts "security.yml not found - please run `./security-setup` and try again."
    exit 1
  end

  YAML.load_file(fname)
end

VAGRANT_PRIVATE_IP_META = "192.168.242.54"
VAGRANT_PRIVATE_IP_CONTROL_01 = "192.168.242.55"
VAGRANT_PRIVATE_IP_WORKER_001 = "192.168.242.56"

Vagrant.configure(2) do |config|
  # Prefer VirtualBox before VMware Fusion
  config.vm.provider "virtualbox"
  config.vm.provider "vmware_fusion"
  config.vm.box = "CiscoCloud/microservices-infrastructure"
  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--cpus', 1]
    vb.customize ['modifyvm', :id, '--memory', 1024]
  end

  # Disable shared folder for control, agent (which don't need source code)
  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"

  # There is no need to provide any provisioning for these machines, as they
  # will be configured via the ansible run in the meta machine.
  config.vm.define "control" do |control|
      control.vm.hostname = "control-01"
      control.vm.network "private_network", :ip => VAGRANT_PRIVATE_IP_CONTROL_01
  end
  config.vm.define "worker" do |worker|
      agent.vm.hostname = "worker-001"
      agent.vm.network "private_network", :ip => VAGRANT_PRIVATE_IP_WORKER_001
  end

  # Must be booted last, as it can only provision active machines
  config.vm.define "meta" do |meta|
      # This is the only machine that needs the Mantl source code
      meta.vm.synced_folder ".", "/vagrant", type: "rsync"
      meta.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', 512]
      end
      meta.vm.hostname = "meta"
      meta.vm.network "private_network", :ip => VAGRANT_PRIVATE_IP_META
      meta.vm.provision "shell" do |s|
        s.path = "vagrant/provision.sh"
        s.args = [VAGRANT_PRIVATE_IP_CONTROL_01, VAGRANT_PRIVATE_IP_WORKER_001]
      end
  end
end
