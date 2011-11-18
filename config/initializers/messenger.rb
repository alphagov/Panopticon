require 'active_record_ext'
require 'messenger'
unless Rails.env.test?
  stomp_url = "failover://(stomp://support.cluster:61613,stomp://support.cluster:61613)"

  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      if forked
        Messenger.transport = Stomp::Client.new stomp_url    
        ActiveRecord::Base.marples_transport = Stomp::Client.new stomp_url
      end
    end
  else
    Messenger.transport = Stomp::Client.new stomp_url
    ActiveRecord::Base.marples_transport = Stomp::Client.new stomp_url
  end
end
