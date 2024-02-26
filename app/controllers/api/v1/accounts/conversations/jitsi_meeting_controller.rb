class Api::V1::Accounts::Conversations::JitsiMeetingController < Api::V1::Accounts::Conversations::BaseController # rubocop:disable Layout/EndOfLine
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

  def create # rubocop:disable Metrics/MethodLength
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

  def nudge
    conversation = @conversation

    agent_name = conversation.assignee&.name || conversation.account.name

    conversation.messages.create!({
                                    account_id: conversation.account_id,
                                    inbox_id: conversation.inbox_id,
                                    message_type: :outgoing,
                                    content_type: :text,
                                    content: "#{agent_name} is sending a nudge",
                                    # content_attributes: {
                                    #   type: 'dyte'
                                    # },
                                    sender: conversation.contact
                                  })

    render json: {
      'message': 'nodge created',
      'conversation': conversation
    }, status: :ok
  end
end
