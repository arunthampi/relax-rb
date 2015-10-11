module Relax
  class Base
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
  end
end
