# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
unless File.exists?("id_rsa")
 system("ssh-keygen -t rsa -f id_rsa -N '' -q")
end 

Vagrant.configure("2") do |config|
  config.vm.base_mac = nil
  
  # devnode - 192.168.56.200
  # developer node with jenkins, git, docker registry

  config.vm.define "devnode" do |devnode|
    devnode.vm.provider "virtualbox" do |vb|
      disk = 'devnode.img'
      vb.memory = 6 * 1024
      vb.cpus = 2
      vb.name = "devnode"
      
      unless File.exist?(disk)
        vb.customize ['createmedium', 'disk', '--filename', disk, '--format', 'vmdk', '--size', 10 * 1024]
      end
      vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk]
    end
    
    devnode.vm.box = "ol76"
    devnode.vm.hostname = "devnode"
    devnode.vm.network "private_network", ip: "192.168.56.200"
    devnode.vm.provision :shell, path: "devnode.sh"
    end

  # kmaster- 192.168.56.201
  # The kubernetes master
  config.vm.define "kmaster" do |kmaster|
    kmaster.vm.provider "virtualbox" do |vb|
      disk = 'kmaster.img'
      vb.memory = 2 * 1024
      vb.cpus = 1
      vb.name = "kmaster"
      
      unless File.exist?(disk)
        vb.customize ['createmedium', 'disk', '--filename', disk, '--format', 'vmdk', '--size', 5 * 1024]
      end
      vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk]
    end
    
    kmaster.vm.box = "ol76"
    kmaster.vm.hostname = "kmaster"
    kmaster.vm.network "private_network", ip: "192.168.56.201"
    kmaster.vm.network "forwarded_port", guest: 8001, host: 8001
    kmaster.vm.provision :shell, path: "kmaster.sh"
  end
  
  # kworker - 192.168.56.202
  # The kubernetes worker node
  config.vm.define "kworker1" do |kworker1|
    kworker1.vm.provider "virtualbox" do |vb|
      disk = 'kworker1.img'
      vb.memory = 2 * 1024
      vb.cpus = 1
      vb.name = "kworker1"
      
      unless File.exist?(disk)
        vb.customize ['createmedium', 'disk', '--filename', disk, '--format', 'vmdk', '--size', 5 * 1024]
      end
      vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk]
    end
    
    kworker1.vm.box = "ol76"
    kworker1.vm.hostname = "kworker1"
    kworker1.vm.network "private_network", ip: "192.168.56.202"
    kworker1.vm.provision :shell, path: "kworker1.sh"
  end
end
