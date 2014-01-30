# Just stash this somewhere for now.
      def self.provision name, runlist, options
        return if runlist.to_s.empty? && !options[:knife_solo]
        instance = get_instance(name)
        key_name = options[:key_name] || Fog.credentials[:key_name]
        if options[:knife_solo]
          system "knife solo bootstrap ubuntu@#{instance.dns_name} " +
                 "#{options[:attributes]} " +
                 "--identity-file ~/.ssh/#{key_name}.pem --node-name #{name} " +
                 "--forward-agent --sudo-command \"sudo -E\" " +
                 "#{"--run-list #{runlist}" if runlist}"
        else
          system "knife bootstrap #{instance.dns_name} " +
                 "--identity-file ~/.ssh/#{key_name}.pem --forward-agent " +
                 "--ssh-user ubuntu --sudo --node-name #{name} " +
                 "--run-list #{runlist}"
        end
      end
