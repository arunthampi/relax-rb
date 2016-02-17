module Relax
  class EventsQueueNotSetError < StandardError; end

  class EventListener < Base
    DEFAULT_LOG_LEVEL        = 'info'

    @@callback = nil
    @@logger = nil

    def self.listen!
      if relax_events_queue.nil? || relax_events_queue == ""
        raise EventsQueueNotSetError, "Environment Variable RELAX_EVENTS_QUEUE is not set"
      end

      self.log("Listening for Relax Events...")

      while true do
        queue_name, event_json = redis.with { |c| c.blpop(relax_events_queue) }

        if queue_name == relax_events_queue
          event = Event.new(JSON.parse(event_json))
          callback.call(event) if callback
        end
      end
    end

    def self.log(text, level = DEFAULT_LOG_LEVEL)
      return if logger.nil?
      logger.send(level, "#{Time.now.strftime('%FT%T%z')}: #{text}")
    end

    def self.callback=(cb)
      @@callback = cb
    end

    def self.callback
      @@callback
    end

    def self.logger=(logger)
      @@logger = logger
    end

    def self.logger
      @@logger
    end

    def self.relax_events_queue
      ENV['RELAX_EVENTS_QUEUE']
    end
  end
end
