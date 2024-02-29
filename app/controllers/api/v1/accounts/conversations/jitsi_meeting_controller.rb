class Api::V1::Accounts::Conversations::JitsiMeetingController < Api::V1::Accounts::Conversations::BaseController
  include JitsiMeetingLink

  def index
    conversation = @conversation
    # get the username from the params

    username = params[:username]

    meeting_url = meeting_url(
      conversation.inbox_id,
      conversation.contact.email,
      conversation.display_id,
      conversation.contact.name,
      username
    )

    render json: {
      'conversation_id': conversation.display_id,
      'meeting_url': meeting_url
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
        conversation.contact.name,
        conversation.assignee&.name
      )
    }, status: :ok
  end

  def end_call
    conversation = @conversation

    # resolve the conversation

    conversation.update!(status: 'resolved')

    conversation.messages.create!({
                                    account_id: conversation.account_id,
                                    inbox_id: conversation.inbox_id,
                                    message_type: :outgoing,
                                    content_type: :text,
                                    content: 'Video call ended'
                                  })

    render json: {
      'message': 'call ended',
      'conversation': conversation
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
