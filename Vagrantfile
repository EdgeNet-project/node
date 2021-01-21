# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "centos8" do |c|
    c.vm.box = "geerlingguy/centos8"
  end

  config.vm.define "debian9" do |c|
    c.vm.box = "debian/contrib-stretch64"
  end

  config.vm.define "fedora32" do |c|
    c.vm.box = "fedora/32-cloud-base"
  end

  config.vm.define "fedora33" do |c|
    c.vm.box = "fedora/33-cloud-base"
  end

  config.vm.define "ubuntu1804" do |c|
    c.vm.box = "ubuntu/bionic64"
  end

  config.vm.define "ubuntu2004" do |c|
    c.vm.box = "ubuntu/focal64"
  end

  config.vm.synced_folder ".", "/node"
end
