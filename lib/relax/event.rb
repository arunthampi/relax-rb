module Relax
  class Event
    attr_accessor :type, :user_uid, :channel_uid, :team_uid, :im, :text,
                  :relax_bot_uid, :timestamp, :provider, :event_timestamp

    def initialize(opts = {})
      opts.each { |k,v| self.send("#{k}=", v) if self.respond_to?("#{k}=") }
    end
  end
end
