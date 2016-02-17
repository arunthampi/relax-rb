module Relax
  class BotsKeyNotSetError < StandardError; end
  class BotsPubsubNotSetError < StandardError; end

  class Bot < Base
    def self.start!(team_uid, token)
      if relax_bots_key.nil? || relax_bots_key == ""
        raise BotsKeyNotSetError, "Environment Variable RELAX_BOTS_KEY is not set"
      end

      if relax_bots_pubsub.nil? || relax_bots_pubsub == ""
        raise BotsPubsubNotSetError, "Environment Variable RELAX_BOTS_PUBSUB is not set"
      end

      redis.with do |conn|
        conn.multi do
          conn.hset(relax_bots_key, team_uid, {team_id: team_uid, token: token}.to_json)
          conn.publish(relax_bots_pubsub, {type: 'team_added', team_id: team_uid}.to_json)
        end
      end
    end

    def self.relax_bots_pubsub
      ENV['RELAX_BOTS_PUBSUB']
    end

    def self.relax_bots_key
      ENV['RELAX_BOTS_KEY']
    end
  end
end
