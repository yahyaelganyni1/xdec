class Api::V1::Widget::JitsiCallsController < Api::V1::Widget::BaseController
  before_action :set_conversation, only: [:create, :index]
  before_action :set_message, only: [:update] # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :set_meeting_url
  include JitsiMeetingLink

  JITSI_SERVER_URL = 'https://jitsi.xdec.io/'.freeze

  def index
    conversation = @conversation

    render json: {
      'message': {
        'meeting_url': @meeting_name,
        'contact_name': conversation.contact.name,
        'conversation_id': conversation.display_id,
        'contact_email': conversation.contact.email,
        'assignee_id': conversation.assignee_id
      }

    }, status: :ok
  end

  def create # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    require 'httparty'
    url = 'http://198.18.133.43:8080/ccp/task/feed/100080'.freeze

    meentin_name = meeting_url(@conversation.inbox_id, @conversation.contact.email, @conversation.display_id, @conversation.contact.name)
    auth_token = request.headers['X-Auth-Token']

    auth_length = auth_token.length

    segment_length = auth_length / 4

    auth_token_1 = auth_token.slice(0, segment_length.ceil)

    auth_token_2 = auth_token.slice(segment_length.ceil, segment_length.ceil)

    auth_token_3 = auth_token.slice(segment_length.ceil * 2, segment_length.ceil)

    auth_token_4 = auth_token.slice(segment_length.ceil * 3, segment_length.ceil)

    p "auth_token: #{auth_token}"

    xml_body = "
    <Task>
    <name>John Doe1</name>
    <title>Help with not my phone</title>
    <description>This is my description</description>
    <scriptSelector>CumulusTask</scriptSelector>
    <requeueOnRecovery>true</requeueOnRecovery>
    <tags>
        <tag>phone</tag>
        <tag>sss</tag>
    </tags>
    <variables>
        <!-- Below two fields are optional fields.
       1) include mediaType to indicate the media type attribute of
          POD when it is created.
       2) If podRefURL is passed then POD creation will be skipped
          for this contact.
    <variable><name>mediaType</name><value>chat</value></variable><variable><name>podRefURL</name><value>https://context-service.rciad.ciscoccservice.com/context/
      pod/v1/podId/b066c3c0-c346-11e5-b3dd-3f1450b33459</value></variable>  -->
      <variable>
          <name>cv_1</name>
          <value>#{auth_token_1}</value>
      </variable>
      <variable>
            <name>cv_2</name>
            <value>#{auth_token_2}</value>
      </variable>
      <variable>
              <name>cv_3</name>
              <value>#{auth_token_3}</value>
    </variable>
    <variable>
            <name>cv_4</name>
            <value>#{auth_token_4}</value>
    </variable>
    <variable>
        <name>user_(eccVariableName)</name>
        <value>eccVariableValue</value>
    </variable>
    <variable>
        <name>anythingElseExtensionFieldName</name>
        <value>anythingElseExtensionFieldValue</value>
    </variable>
  </variables>
</Task>
    "

    response = HTTParty.post(url,
                             body: xml_body,
                             headers: { 'Content-Type' => 'application/xml' },
                             basic_auth: { username: 'administrator', password: 'C1sco12345' })

    p '--------====response-header-location====--------'
    p response.headers['location']
    p '--------====response====--------'

    # to reassign the conversation to another agent when the call is started by the customer you can uncomment the below line
    # @conversation.update!(assignee_id: 3)

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

  def start_call # rubocop:disable Metrics/MethodLength
    recived_data = params[:data]
    assignee_id = recived_data[:agent_id]
    @conversation.update!(assignee_id: assignee_id) # if assignee_id.present? && @conversation.assignee_id != assignee_id

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

    p "token_from_jitsi: #{@token}"

    render json: {
      'message': {
        'meeting_url': @meeting_name,
        'contact_name': conversation.contact.name,
        'conversation_id': conversation.display_id,
        'contact_email': conversation.contact.email,
        'assignee_id': conversation.assignee_id,
        'agent_name': agent_name,
        'recived_data': recived_data,
        'website_token': @web_widget.website_token,
        'recived_data': recived_data # rubocop:disable Lint/DuplicateHashKey
      }
    }
  end

  def end_call # rubocop:disable Metrics/MethodLength
    require 'httparty'
    # url = 'http://198.18.133.43:8080/ccp/task/feed/100080'.freeze

    url = params[:Location]

    HTTParty.delete(url,
                    headers: { 'Content-Type' => 'application/xml' },
                    basic_auth: { username: 'administrator', password: 'C1sco12345' })

    @conversation.messages.create!({
                                     content: 'you cancelled the video call',
                                     content_type: :integrations,
                                     account_id: @conversation.account_id,
                                     inbox_id: @conversation.inbox_id,
                                     message_type: :outgoing,
                                     private: false,
                                     content_attributes: {
                                       type: 'text'
                                     },
                                     sender: @conversation.contact
                                   })

    render json: {
      'message': 'meeting ended',
      'Location': url
    }
  end

  private

  def set_conversation
    @conversation = create_conversation if conversation.nil?
  end

  def set_message
    @message = @web_widget.inbox.messages.find(permitted_params[:id])
  end

  def set_meeting_url
    @meeting_name = meeting_url(
      conversation.inbox_id,
      conversation.contact.email,
      conversation.display_id,
      conversation.contact.name
    )
  end
end
