class Api::V1::Widget::JitsiCallsController < Api::V1::Widget::BaseController # rubocop:disable Layout/EndOfLine
  before_action :set_conversation, only: [:create, :index]
  before_action :set_message, only: [:update]
  include JitsiMeetingLink

  JITSI_SERVER_URL = 'https://jitsi.xdec.io/'.freeze

  def index
    conversation = @conversation

    render json: {
      'message': {
        'meeting_url': meeting_url(
          conversation.inbox_id,
          conversation.contact.email,
          conversation.display_id,
          conversation.contact.name
        ),
        'contact_name': conversation.contact.name,
        'conversation_id': conversation.display_id,
        'contact_email': conversation.contact.email,
        'assignee_id': conversation.assignee_id
      }

    }, status: :ok
  end

  def create # rubocop:disable Metrics/MethodLength
    @conversation.messages.create!({
                                     content: "#{@conversation.contact.name} has started a video call",
                                     content_type: :integrations,
                                     account_id: @conversation.account_id,
                                     inbox_id: @conversation.inbox_id,
                                     message_type: :incoming,
                                     private: false,
                                     content_attributes: {
                                       type: 'dyte'
                                     },
                                     sender: @conversation.contact

                                   })

    render json: {
      'message': {
        'conversation_id': @conversation.display_id,
        'meeting_url': meeting_url(@conversation.inbox_id, @conversation.contact.email, @conversation.display_id, @conversation.contact.name),
        'assignee_id': conversation.assignee_id,
        'agent_name': conversation.assignee&.name
      }
    }, status: :ok
  end

  private

  def set_conversation
    @conversation = create_conversation if conversation.nil?
  end

  def set_message
    @message = @web_widget.inbox.messages.find(permitted_params[:id])
  end
end
