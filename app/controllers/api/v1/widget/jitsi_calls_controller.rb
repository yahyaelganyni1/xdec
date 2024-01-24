class Api::V1::Widget::JitsiCallsController < Api::V1::Widget::BaseController
  before_action :set_conversation, only: [:create, :index]
  before_action :set_message, only: [:update] # rubocop:disable Rails/LexicallyScopedActionFilter
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
    require 'httparty'
    url = 'http://198.18.133.43:8080/ccp/task/feed/100080'.freeze

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
                <value>callVariableValue</value>
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

    HTTParty.post(url,
                  body: xml_body,
                  headers: { 'Content-Type' => 'application/xml' },
                  basic_auth: { username: 'administrator', password: 'administrator' })

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
