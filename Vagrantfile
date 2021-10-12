
Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/focal64"

  config.vm.provision "shell", path: "script.sh"

  config.vm.provider "virtualbox" do |vb|
    # Customize the amount of memory on the VM:
    vb.memory = "6144"
  end
  
end
