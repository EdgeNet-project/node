# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "centos8" do |c|
    c.vm.box = "geerlingguy/centos8"
    c.vm.network "private_network", ip: "192.168.210.100"
  end

  config.vm.define "debian9" do |c|
    c.vm.box = "debian/contrib-stretch64"
    c.vm.network "private_network", ip: "192.168.210.101"
  end

  config.vm.define "fedora32" do |c|
    c.vm.box = "fedora/32-cloud-base"
    c.vm.network "private_network", ip: "192.168.210.102"
  end

  config.vm.define "fedora33" do |c|
    c.vm.box = "fedora/33-cloud-base"
    c.vm.network "private_network", ip: "192.168.210.103"
  end

  config.vm.define "ubuntu1804" do |c|
    c.vm.box = "ubuntu/bionic64"
    c.vm.network "private_network", ip: "192.168.210.104"
  end

  config.vm.define "ubuntu2004" do |c|
    c.vm.box = "ubuntu/focal64"
    c.vm.network "private_network", ip: "192.168.210.105"
  end

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
  end

  config.vm.synced_folder ".", "/node"
  config.vm.synced_folder ".", "/vagrant", disabled: true
end
