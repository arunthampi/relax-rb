require 'spec_helper'

describe Relax::Bot do
  describe '.start!' do
    context "when ENV['RELAX_BOTS_KEY'] is nil" do
      it 'should raise an error' do
        expect {
          Relax::Bot.start!('team_id', 'token')
        }.to raise_error Relax::BotsKeyNotSetError
      end
    end

    context "when ENV['RELAX_BOTS_KEY'] is present and ENV['RELAX_BOTS_PUBSUB'] is nil" do
      before do
        ENV['RELAX_BOTS_KEY'] = 'relax_bots_key'
      end

      after do
        ENV['RELAX_BOTS_KEY'] = nil
      end

      it 'should raise an error' do
        expect {
          Relax::Bot.start!('team_id', 'token')
        }.to raise_error Relax::BotsPubsubNotSetError
      end
    end

    context "when ENV['RELAX_BOTS_KEY'] and ENV['RELAX_BOTS_PUBSUB'] are present" do
      before do
        ENV['RELAX_BOTS_KEY'] = 'relax_bots_key'
        ENV['RELAX_BOTS_PUBSUB'] = 'relax_bots_pubsub'

        Relax::Bot.redis.flushdb
        @redis_subscriber = Redis.new(uri: URI.parse("redis://localhost:6379"), db: 0)
      end

      after do
        ENV['RELAX_BOTS_KEY'] = nil
        ENV['RELAX_BOTS_PUBSUB'] = nil
      end

      it 'should push the entry to the queue (to be consumed by nestorbot)' do
        thread = Thread.new do
          @redis_subscriber.subscribe(ENV['RELAX_BOTS_PUBSUB']) do |on|
            on.subscribe do |channel, total|
              @subscribed = true
            end

            on.message do |channel, message|
              @pubsub_message = message
              @redis_subscriber.unsubscribe
            end
          end
        end

        Thread.pass while !@subscribed
        Relax::Bot.start!('team_id', 'token')
        thread.join

        @message = JSON.parse(@redis_subscriber.hget(ENV['RELAX_BOTS_KEY'], 'team_id'))
        expect(@message['team_id']).to eql 'team_id'
        expect(@message['token']).to eql 'token'
        expect(JSON.parse(@pubsub_message)['team_id']).to eql 'team_id'
        expect(@subscribed).to be_truthy
      end
    end
  end
end
