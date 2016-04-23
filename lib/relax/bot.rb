require 'securerandom'

module Relax
  class BotsKeyNotSetError < StandardError; end
  class BotsPubsubNotSetError < StandardError; end

  class Bot < Base
    def self.start!(team_uid, token, opts = {})
      if relax_bots_key.nil? || relax_bots_key == ""
        raise BotsKeyNotSetError, "Environment Variable RELAX_BOTS_KEY is not set"
      end

      if relax_bots_pubsub.nil? || relax_bots_pubsub == ""
        raise BotsPubsubNotSetError, "Environment Variable RELAX_BOTS_PUBSUB is not set"
      end

      namespace = (opts[:namespace] || opts['namespace']).to_s.strip
      hset_payload = {team_id: team_uid, token: token}
      hset_payload.merge!(namespace: namespace) if namespace != ""
      key = namespace == "" ? team_uid : "#{namespace}-#{team_uid}"

      redis.with do |conn|
        conn.multi do
          conn.hset(relax_bots_key, key, hset_payload.to_json)
          conn.publish(relax_bots_pubsub, {type: 'team_added', team_id: team_uid}.to_json)
        end
      end
    end

    def self.start_typing!(team_uid, channel_uid)
      if relax_bots_key.nil? || relax_bots_key == ""
        raise BotsKeyNotSetError, "Environment Variable RELAX_BOTS_KEY is not set"
      end

      if relax_bots_pubsub.nil? || relax_bots_pubsub == ""
        raise BotsPubsubNotSetError, "Environment Variable RELAX_BOTS_PUBSUB is not set"
      end

      message_id = SecureRandom.uuid
      payload = { id: message_id, type: 'typing', channel: channel_uid }.to_json

      redis.with do |conn|
        conn.publish(relax_bots_pubsub, {type: 'message', team_id: team_uid, id: message_id, payload: payload}.to_json)
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
