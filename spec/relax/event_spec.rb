require 'spec_helper'

describe Relax::Event do
  describe '#to_hash' do
    let!(:event) { Relax::Event.new(
      type: 'message_new',
      user_uid: 'user_uid',
      channel_uid: 'channel_uid',
      team_uid: 'team_uid',
      im: true,
      text: 'hello world',
      relax_bot_uid: 'URELAXBOT',
      timestamp: '1000000.1',
      provider: 'slack',
      event_timestamp: '1000000.2')
    }

    it 'should return a hash with all of the attributes' do
      hash = event.to_hash
      expect(hash[:type]).to eql 'message_new'
      expect(hash[:user_uid]).to eql 'user_uid'
      expect(hash[:channel_uid]).to eql 'channel_uid'
      expect(hash[:team_uid]).to eql 'team_uid'
      expect(hash[:im]).to eql true
      expect(hash[:text]).to eql 'hello world'
      expect(hash[:relax_bot_uid]).to eql 'URELAXBOT'
      expect(hash[:timestamp]).to eql '1000000.1'
      expect(hash[:provider]).to eql 'slack'
      expect(hash[:event_timestamp]).to eql '1000000.2'
    end
  end

  describe '#==' do
    let!(:event) { Relax::Event.new(
      type: 'message_new',
      user_uid: 'user_uid',
      channel_uid: 'channel_uid',
      team_uid: 'team_uid',
      im: true,
      text: 'hello world',
      relax_bot_uid: 'URELAXBOT',
      timestamp: '1000000.1',
      provider: 'slack',
      event_timestamp: '1000000.2')
    }

    let(:other_event) { event.dup }

    it 'should return true for event == other_event' do
      expect(event == other_event).to be_truthy
      expect(event).to eql other_event

      other_event.timestamp = '1000000.2'
      expect(event == other_event).to be_falsy
      expect(event).to_not eql other_event
    end
  end
end
