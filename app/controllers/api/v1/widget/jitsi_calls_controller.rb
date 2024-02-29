class Api::V1::Widget::JitsiCallsController < Api::V1::Widget::BaseController
  before_action :set_conversation, only: [:create, :index]
  before_action :set_message, only: [:update] # rubocop:disable Rails/LexicallyScopedActionFilter
  # before_action :set_meeting_url
  include JitsiMeetingLink

  def index
    conversation = @conversation
    # get the username from the params
    username = params[:username]
    render json: {
      'message': {
        'meeting_url': meeting_url(
          conversation.inbox_id,
          conversation.contact.email,
          conversation.display_id,
          conversation.contact.name,
          username
        ),
        'contact_name': conversation.contact.name,
        'conversation_id': conversation.display_id,
        'contact_email': conversation.contact.email,
        'assignee_id': conversation.assignee_id,
        'username': username
      }
    }, status: :ok
  end

  # start the call from the agent side (from the cesco side)
  def create # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    require 'httparty'
    require 'json'
    # the cesco server url

    meentin_name = meeting_url(@conversation.inbox_id,
                               @conversation.contact.email,
                               @conversation.display_id,
                               @conversation.contact.name, '@conversation.assignee&.name')

    @conversation.messages.create!({
                                     content: "#{conversation.contact.name} requested a video call",
                                     content_type: :text,
                                     account_id: @conversation.account_id,
                                     inbox_id: @conversation.inbox_id,
                                     message_type: :incoming,
                                     private: false,
                                     content_attributes: {
                                       type: 'text'
                                     },
                                     sender: @conversation.contact
                                   })

    auth_token = request.headers['X-Auth-Token']
    url = ENV.fetch('CISCO_FINESSE_URL')

    response = HTTParty.post(url,
                             verify: false,
                             body: {
                               'name': @conversation.contact.name,
                               'auth_token': auth_token,
                               'assignee_id': @conversation.assignee_id,
                               'meeting_url': meentin_name,
                               'conversation_id': @conversation.display_id,
                               'contact_email': @conversation.contact.email
                             }.to_json,
                             headers: { 'Content-Type' => 'application/json' })

    render json: {
      'message': {
        'conversation_id': @conversation.display_id,
        'meeting_url': meentin_name,
        'assignee_id': conversation.assignee_id,
        'agent_name': conversation.assignee&.name,
        'task_location': response.headers['location']
      }
    }, status: :ok
  end

  # to start the call from the customer side
  def start_call # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    # to reassign the conversation to another agent when the call is started by the customer you can uncomment the below line
    recived_data = params[:data]
    assignee_id = recived_data[:agent_id]

    if assignee_id.present? && !User.exists?(assignee_id)
      render json: { error: 'Invalid assignee ID' }, status: :unprocessable_entity
      return
    end

    conversation.update!(assignee_id: assignee_id) # if assignee_id.present? && @conversation.assignee_id != assignee_id

    agent_name = @conversation.assignee&.name

    @conversation.messages.create!({
                                     content: "#{agent_name} accepted the video call",
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
      'message': {
        'meeting_url': meeting_url(
          @conversation.inbox_id,
          @conversation.contact.email,
          @conversation.display_id,
          @conversation.contact.name,
          @conversation.assignee&.name
        ),

        'contact_name': conversation.contact.name,
        'conversation_id': conversation.display_id,
        'contact_email': conversation.contact.email,
        'assignee_id': conversation.assignee_id,
        'agent_name': agent_name,
        'recived_data': recived_data,
        'website_token': @web_widget.website_token,
        'recived_data': recived_data # rubocop:disable Lint/DuplicateHashKey
      }
    }, status: :ok
  end

  def nodge
    # to send a nudge message to the coustomer you can use the below code
    agent_name = @conversation.assignee&.name
    coustomer_name = @conversation.contact.name

    nudge_message = "#{agent_name} is nodging #{coustomer_name}"

    @conversation.messages.create!({
                                     content: nudge_message,
                                     content_type: :text,
                                     account_id: @conversation.account_id,
                                     inbox_id: @conversation.inbox_id,
                                     message_type: :outgoing,
                                     private: false,
                                     content_attributes: {
                                       type: 'text'
                                     },
                                     sender: @conversation.assignee
                                   })

    render json: {
      'message': 'nodge'
    }, status: :ok
  end

  #  to end the call from the customer side
  def end_call
    url = params[:Location]

    # resolve call when ending

    @conversation.update!(status: 'resolved')

    contact_name = @conversation.contact.name
    # send a message in the chat from the customer side that the call is ended
    @conversation.messages.create!({
                                     content: "#{contact_name} cancelled the video call",
                                     content_type: :integrations,
                                     account_id: @conversation.account_id,
                                     inbox_id: @conversation.inbox_id,
                                     message_type: :incoming,
                                     private: false,
                                     content_attributes: {
                                       type: 'text'
                                     },
                                     sender: @conversation.contact
                                   })

    render json: {
      'message': 'meeting ended',
      'Location': url

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
