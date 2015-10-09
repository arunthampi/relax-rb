require "relax/version"
require "redis"
require "json"

class Relax
  class Event
    attr_accessor :user_uid, :channel_uid, :team_uid, :im, :text,
                  :relax_bot_uid, :timestamp, :provider, :event_timestamp

    def initialize(opts = {})
      opts.each { |k,v| self.send("#{k}=", v) if self.respond_to?("#{k}=") }
    end
  end

  class RelaxBotsKeyNotSetError < StandardError; end
  class RelaxBotsPubsubNotSetError < StandardError; end
  class RelaxEventsQueueNotSetError < StandardError; end

  def self.start_bot!(team_uid, token)
    if relax_bots_key.nil? || relax_bots_key == ""
      raise RelaxBotsKeyNotSetError, "Environment Variable RELAX_BOTS_KEY is not set"
    end

    if relax_bots_pubsub.nil? || relax_bots_pubsub == ""
      raise RelaxBotsPubsubNotSetError, "Environment Variable RELAX_BOTS_PUBSUB is not set"
    end

    redis.multi do
      redis.hset(relax_bots_key, team_uid, {team_id: team_uid, token: token}.to_json)
      redis.publish(relax_bots_pubsub, {type: 'team_added', team_id: team_uid}.to_json)
    end
  end

  def self.listen_for_events
    if relax_events_queue.nil? || relax_events_queue == ""
      raise RelaxEventsQueueNotSetError, "Environment Variable RELAX_EVENTS_QUEUE is not set"
    end

    while true do
      queue_name, event_json = redis.blpop(relax_events_queue)

      if queue_name == relax_events_queue
        event = Event.new(JSON.parse(event_json))
        callback.call(event) if callback
      end
    end
  end

  def self.redis
    if uri = ENV['REDISTOGO_URL']
      redis_uri = URI.parse(uri)
    elsif uri = ENV['REDIS_URL']
      redis_uri = URI.parse(uri)
    else
      redis_uri = URI.parse("redis://localhost:6379")
    end

    @@redis ||= Redis.new(url: redis_uri, db: 0)
  end

  def self.callback=(cb)
    @@callback = cb
  end

  def self.callback
    @@callback
  end

  def self.relax_events_queue
    ENV['RELAX_EVENTS_QUEUE']
  end

  def self.relax_bots_pubsub
    ENV['RELAX_BOTS_PUBSUB']
  end

  def self.relax_bots_key
    ENV['RELAX_BOTS_KEY']
  end
end
