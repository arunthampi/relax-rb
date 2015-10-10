require 'spec_helper'

describe Relax do
  it 'has a version number' do
    expect(Relax::VERSION).not_to be nil
  end

  describe '.start_bot!' do
    context "when ENV['RELAX_BOTS_KEY'] is nil" do
      it 'should raise an error' do
        expect {
          Relax.start_bot!('team_id', 'token')
        }.to raise_error Relax::RelaxBotsKeyNotSetError
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
          Relax.start_bot!('team_id', 'token')
        }.to raise_error Relax::RelaxBotsPubsubNotSetError
      end
    end

    context "when ENV['RELAX_BOTS_KEY'] and ENV['RELAX_BOTS_PUBSUB'] are present" do
      before do
        ENV['RELAX_BOTS_KEY'] = 'relax_bots_key'
        ENV['RELAX_BOTS_PUBSUB'] = 'relax_bots_pubsub'

        Relax.redis.flushdb
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
        Relax.start_bot!('team_id', 'token')
        thread.join

        @message = JSON.parse(@redis_subscriber.hget(ENV['RELAX_BOTS_KEY'], 'team_id'))
        expect(@message['team_id']).to eql 'team_id'
        expect(@message['token']).to eql 'token'
        expect(JSON.parse(@pubsub_message)['team_id']).to eql 'team_id'
        expect(@subscribed).to be_truthy
      end
    end
  end

  describe '.listen_for_events' do
    context "when ENV['RELAX_EVENTS_QUEUE'] is nil" do
      it 'should raise an error' do
        expect {
          Relax.listen_for_events
        }.to raise_error Relax::RelaxEventsQueueNotSetError
      end
    end

    context "when ENV['RELAX_EVENTS_QUEUE'] is set" do
      before do
        ENV['RELAX_EVENTS_QUEUE'] = 'relax_events_queue'
        Relax.redis.flushdb

        @redis = Redis.new(uri: URI.parse("redis://localhost:6379"), db: 0)
        @thread = Thread.new { Relax.listen_for_events }

        Relax.callback = Proc.new { |e| @event = e; @thread.join }

        @redis.rpush(ENV['RELAX_EVENTS_QUEUE'], {
          type: 'message_new',
          user_uid: 'user_uid',
          channel_uid: 'channel_uid',
          team_uid: 'team_uid',
          im: true,
          text: 'hello world',
          relax_bot_uid: 'URELAXBOT',
          timestamp: '1000000.1',
          provider: 'slack',
          event_timestamp: '1000000.2'
        }.to_json)
      end

      after do
        ENV['RELAX_EVENTS_QUEUE'] = nil
      end

      it 'should callback with the event' do
        Thread.pass while !@event

        expect(@event).to be_a(Relax::Event)
        expect(@event.type).to eql 'message_new'
        expect(@event.user_uid).to eql 'user_uid'
        expect(@event.channel_uid).to eql 'channel_uid'
        expect(@event.team_uid).to eql 'team_uid'
        expect(@event.im).to eql true
        expect(@event.text).to eql 'hello world'
        expect(@event.relax_bot_uid).to eql 'URELAXBOT'
        expect(@event.timestamp).to eql '1000000.1'
        expect(@event.provider).to eql 'slack'
        expect(@event.event_timestamp).to eql '1000000.2'
      end
    end
  end
end
