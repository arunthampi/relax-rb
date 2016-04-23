module Relax
  class Event
    ATTRIBUTES = [:type, :user_uid, :channel_uid, :team_uid, :im, :text,
                  :relax_bot_uid, :timestamp, :provider, :event_timestamp,
                  :namespace]

    attr_accessor *ATTRIBUTES

    def initialize(opts = {})
      opts.each { |k,v| self.send("#{k}=", v) if self.respond_to?("#{k}=") }
    end

    def to_hash
      hash = {}
      ATTRIBUTES.each { |a| hash[a] = self.send(a) }
      hash
    end

    def ==(other)
      other.respond_to?('channel_uid') &&
      other.respond_to?('timestamp') &&
      self.channel_uid == other.channel_uid &&
      self.timestamp == other.timestamp
    end
    alias_method :eql?, :==
  end
end
