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

        Relax::Bot.redis.with { |c| c.flushdb }
        @redis_subscriber = Redis.new(uri: URI.parse("redis://localhost:6379"), db: 0)
      end

      after do
        ENV['RELAX_BOTS_KEY'] = nil
        ENV['RELAX_BOTS_PUBSUB'] = nil
      end

      context 'without namesapce' do
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
          expect(@message['namespace']).to be_nil

          m = JSON.parse(@pubsub_message)
          expect(m['team_id']).to eql 'team_id'
          expect(m['namespace']).to be_nil
          expect(@subscribed).to be_truthy
        end
      end

      context 'with namesapce' do
        it 'should push the entry to the queue (to be consumed by nestorbot) with the namespace' do
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
          Relax::Bot.start!('team_id', 'token', namespace: 'namespace')
          thread.join

          @message = JSON.parse(@redis_subscriber.hget(ENV['RELAX_BOTS_KEY'], 'namespace-team_id'))
          expect(@message['team_id']).to eql 'team_id'
          expect(@message['token']).to eql 'token'
          expect(@message['namespace']).to eql 'namespace'

          m = JSON.parse(@pubsub_message)
          expect(m['team_id']).to eql 'team_id'
          expect(m['namespace']).to eql 'namespace'
          expect(@subscribed).to be_truthy
        end
      end

    end
  end

  describe '.start_typing!' do
    context "when ENV['RELAX_BOTS_KEY'] is nil" do
      it 'should raise an error' do
        expect {
          Relax::Bot.start_typing!('team_id', 'channel_id')
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
          Relax::Bot.start_typing!('team_id', 'channel_id')
        }.to raise_error Relax::BotsPubsubNotSetError
      end
    end

    context "when ENV['RELAX_BOTS_KEY'] and ENV['RELAX_BOTS_PUBSUB'] are present" do
      before do
        ENV['RELAX_BOTS_KEY'] = 'relax_bots_key'
        ENV['RELAX_BOTS_PUBSUB'] = 'relax_bots_pubsub'

        Relax::Bot.redis.with { |c| c.flushdb }
        @redis_subscriber = Redis.new(uri: URI.parse("redis://localhost:6379"), db: 0)
        allow(SecureRandom).to receive(:uuid).and_return('uuid')
      end

      after do
        ENV['RELAX_BOTS_KEY'] = nil
        ENV['RELAX_BOTS_PUBSUB'] = nil
      end

      it 'should send an event to Redis with a Slack payload for typing' do
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
        Relax::Bot.start_typing!('team_id', 'channel_id')
        thread.join

        expect(@subscribed).to be_truthy
        message = JSON.parse(@pubsub_message)
        expect(message['team_id']).to eql 'team_id'
        expect(message['id']).to eql 'uuid'
        expect(message['type']).to eql 'message'

        expect(JSON.parse(message['payload'])).to eql({'id' => 'uuid', 'type' => 'typing', 'channel' => 'channel_id'})
      end
    end
  end
end
