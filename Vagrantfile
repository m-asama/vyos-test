Vagrant.configure("2") do |config|

  config.vm.box = 'vyos'

  (1..5).each do |i|
    config.vm.define "vyos#{i}" do |v|
      (1..5).each do |j|
        v.vm.network "private_network",
            ip: "127.#{i}.#{j}.0",
            auto_config: false,
            virtualbox__intnet: "vyosnet#{j}"
      end
    end
  end

end
