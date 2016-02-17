require 'spec_helper'

describe Relax::EventListener do
  describe '.listen!' do
    context "when ENV['RELAX_EVENTS_QUEUE'] is nil" do
      it 'should raise an error' do
        expect {
          Relax::EventListener.listen!
        }.to raise_error Relax::EventsQueueNotSetError
      end
    end

    context "when ENV['RELAX_EVENTS_QUEUE'] is set" do
      before do
        ENV['RELAX_EVENTS_QUEUE'] = 'relax_events_queue'
        Relax::EventListener.redis.with { |c| c.flushdb }

        @redis = Redis.new(uri: URI.parse("redis://localhost:6379"), db: 0)
        @thread = Thread.new { Relax::EventListener.listen! }

        Relax::EventListener.callback = Proc.new { |e| @event = e; @thread.join }

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
