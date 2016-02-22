module Relax
  class Base
    def self.redis
      if uri = ENV['REDISCLOUD_URL']
        redis_uri = URI.parse(uri)
      elsif uri = ENV['REDISTOGO_URL']
        redis_uri = URI.parse(uri)
      elsif uri = ENV['REDIS_URL']
        redis_uri = URI.parse(uri)
      else
        redis_uri = URI.parse("redis://localhost:6379")
      end

      if !defined?(@@conn)
        @@conn = ConnectionPool.new(timeout: 1, size: 2) do
          Redis.new(url: redis_uri, db: 0)
        end
      end

      @@conn
    end
  end
end
