Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"  # Ubuntu 22.04 LTS
  config.vm.network "private_network", type: "dhcp"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    # Actualizar e instalar MongoDB
    sudo apt-get update
    sudo apt-get install -y wget gnupg
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org
    sudo systemctl start mongod
    sudo systemctl enable mongod

    # Instalar dependencias adicionales
    sudo apt-get install -y python3-pip zip
    sudo pip3 install azure-identity azure-storage-blob

    # Crear directorios y archivos necesarios
    sudo mkdir -p /mongodb_backup/{scripts,backups,logs}
    
    # Aquí añadiremos el contenido de los scripts
  SHELL
end