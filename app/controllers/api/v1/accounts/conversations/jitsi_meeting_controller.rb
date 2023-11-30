class Api::V1::Accounts::Conversations::JitsiMeetingController < Api::V1::Accounts::Conversations::BaseController
  include JitsiMeetingLink

  def index
    conversation = @conversation

    render json: {
      'conversation_id': conversation.display_id,
      'meeting_url': meeting_url(
        conversation.inbox_id,
        conversation.contact.email,
        conversation.display_id,
        conversation.contact.name
      )
    }, status: :ok
  end

  def create
    conversation = @conversation
    conversation.messages.create!({
                                    account_id: conversation.account_id,
                                    inbox_id: conversation.inbox_id,
                                    message_type: :outgoing,
                                    content_type: :integrations,
                                    content: 'Video call started',
                                    content_attributes: {
                                      type: 'dyte'
                                    },
                                    sender: conversation.contact
                                  })
    render json: {
      'conversation_id': conversation.display_id,
      'meeting_url': meeting_url(
        conversation.inbox_id,
        conversation.contact.email,
        conversation.display_id,
        conversation.contact.name
      )
    }, status: :ok
  end
end
