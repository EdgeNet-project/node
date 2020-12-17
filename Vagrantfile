# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "centos7" do |c|
    c.vm.box = "generic/centos7"
    c.vm.network "private_network", ip: "192.168.210.20"
  end

  config.vm.define "debian9" do |c|
    c.vm.box = "generic/debian9"
    c.vm.network "private_network", ip: "192.168.210.30"
  end

  # config.vm.define "fedora25" do |c|
  #   c.vm.box = "generic/fedora25"
  #   c.vm.network "private_network", ip: "192.168.210.40"
  # end

  config.vm.define "fedora31" do |c|
    c.vm.box = "generic/fedora31"
    c.vm.network "private_network", ip: "192.168.210.40"
  end

  config.vm.define "ubuntu1604" do |c|
    c.vm.box = "generic/ubuntu1604"
    c.vm.network "private_network", ip: "192.168.210.50"
  end

  config.vm.synced_folder ".", "/node"
end
