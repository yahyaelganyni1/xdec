class Call < ApplicationRecord # rubocop:disable Layout/EndOfLine
  has_many :call_participants # rubocop:disable Rails/HasManyOrHasOneDependent
  belongs_to :conversation

  def self.create_call(conversation, agent, contact_id, started_at)
    Call.create!(conversation: conversation, agent: agent, contact_id: contact_id, started_at: started_at)
  end

  def end_call(ended_at)
    update!(ended_at: ended_at)
  end

  def self.find_call(conversation_id)
    find_by(conversation_id: conversation_id)
  end
end
