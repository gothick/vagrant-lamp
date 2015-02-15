# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# We keep basic settings in vagrant_settings.yml. The idea is that
# each of our web projects will include this project as a git submodule,
# and we can override anything we need by providing a project-specific
# settings file in the parent directory (probably the project root.)
# i.e. 
# project_directory
#   vagrant_settings.yml <-- per-project settings
#   vagrant <-- This project as a git submodule
#     vagrant_settings.yml <-- default settings

settings = YAML.load_file("vagrant_settings.yml")

if File.exists? ("../vagrant_settings.yml")
	user_settings = YAML.load_file("../vagrant_settings.yml")
	settings.merge!(user_settings)
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = "ubuntu/trusty64"

	# Create a private network, which allows host-only access to the machine
	# using a specific IP.
	config.vm.network "private_network", ip: settings['network']['ip_address']

	# If you're using the vagrant-hostsupdater plugin, this will also get added
	# to your hosts file
	config.vm.hostname = settings['network']['hostname']

	if settings['network'].has_key?('aliases') 
		config.hostsupdater.aliases = settings['network']['aliases']
	end

	settings['synced_folders'].each do |folder|
		config.vm.synced_folder folder['host'], folder['guest'], folder['mount_options']
	end

    # VirtualBox specific stuff. The main thing I want to do is allow
    # DNS, etc.
	config.vm.provider :virtualbox do |vb|
		# vb.customize ["modifyvm", :id, "--cpus", "2" ]
	    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    	vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
	end

	config.vm.provision "shell", path: "provision.sh"

end
