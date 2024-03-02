class Call < ApplicationRecord
  has_many :call_participants # rubocop:disable Rails/HasManyOrHasOneDependent
  belongs_to :conversation

  def self.create_call(conversation, _agent, contact_id, started_at)
    Call.create!(conversation: conversation, agent_id: 2, contact_id: contact_id, started_at: started_at)
  end

  def end_call(ended_at)
    update!(ended_at: ended_at)
  end

  def self.find_call(call_id)
    Call.find(call_id)
  end
end
