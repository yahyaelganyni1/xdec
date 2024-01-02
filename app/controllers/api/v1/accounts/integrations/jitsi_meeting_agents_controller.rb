class Api::V1::Accounts::Integrations::JitsiMeetingAgentsController < Api::V1::Accounts::BaseController
  before_action :set_conversation, only: [:create, :show]
  # before_action :authorize_request
  include JitsiMeetingLink

  def show
    render json: {
      'conversation_id_from the params': @conversation.display_id,
      'meeting_url': meeting_url(
        @conversation.inbox_id,
        @conversation.contact.email,
        @conversation.id,
        @conversation.contact.name
      )
    }, status: :ok
  end

  def create # rubocop:disable Metrics/MethodLength
    @conversation.messages.create!({
                                     content: "#{@conversation.assignee&.name} has started a video call",
                                     content_type: :integrations,
                                     account_id: @conversation.account_id,
                                     inbox_id: @conversation.inbox_id,
                                     message_type: :outgoing,
                                     private: false,
                                     content_attributes: {
                                       type: 'dyte'
                                     },
                                     sender: @conversation.contact

                                   })
    render json: {
      'conversation_id_from the params': @conversation.display_id,
      'conversation_id': @conversation.id,
      'contact': @conversation.contact,
      'meeting_url': meeting_url(
        @conversation.inbox_id,
        @conversation.contact.email,
        @conversation.id,
        @conversation.contact.name
      )
    }, status: :ok
  end

  private

  def set_conversation
    @conversation = Conversation.find_by(display_id: params[:conversation_id])
  end
end
