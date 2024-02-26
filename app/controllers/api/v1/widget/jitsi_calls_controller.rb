class Api::V1::Widget::JitsiCallsController < Api::V1::Widget::BaseController # rubocop:disable Metrics/ClassLength
  before_action :set_conversation, only: [:create, :index]
  before_action :set_message, only: [:update] # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :set_meeting_url
  include JitsiMeetingLink

  # JITSI_SERVER_URL = 'https://jitsi.xdec.io/'.freeze

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

  # start the call from the agent side (from the cesco side)
  def create # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    require 'httparty'
    # the cesco server url
    url = ENV.fetch('CISCO_FINESSE_URL')

    meentin_name = meeting_url(@conversation.inbox_id, @conversation.contact.email, @conversation.display_id, @conversation.contact.name)
    auth_token = request.headers['X-Auth-Token']

    # finees_request(auth_token)

    auth_length = auth_token.length
    #  slice the auth token into 4 segments for the cesco xml can take it
    segment_length = auth_length / 4

    auth_token_1 = auth_token.slice(0, segment_length.ceil)

    auth_token_2 = auth_token.slice(segment_length.ceil, segment_length.ceil)

    auth_token_3 = auth_token.slice(segment_length.ceil * 2, segment_length.ceil)

    auth_token_4 = auth_token.slice(segment_length.ceil * 3, segment_length.ceil)

    # the xml body that will be sent to the cesco server
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

    # response = HTTParty.post(url,
    #                          body: xml_body,
    #                          headers: { 'Content-Type' => 'application/xml' },
    #                          basic_auth: { username: ENV.fetch('CISCO_FINESSE_USERNAME'),
    #                                        password: ENV.fetch('CISCO_FINESSE_PASSWORD') })

    # unless response.success?
    #   render json: { 'error': 'Request to Cisco server failed' }, status: :internal_server_error
    #   @conversation.messages.create!({
    #                                    content: 'Request to Cisco server failed',
    #                                    content_type: :text,
    #                                    account_id: @conversation.account_id,
    #                                    inbox_id: @conversation.inbox_id,
    #                                    message_type: :incoming,
    #                                    private: false,
    #                                    content_attributes: {
    #                                      type: 'text'
    #                                    },
    #                                    sender: @conversation.contact
    #                                  })

    #   return
    # end

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

  # to start the call from the customer side
  def start_call # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    # to reassign the conversation to another agent when the call is started by the customer you can uncomment the below line
    recived_data = params[:data]
    assignee_id = recived_data[:agent_id]

    if assignee_id.present? && !User.exists?(assignee_id)
      render json: { error: 'Invalid assignee ID' }, status: :unprocessable_entity
      return
    end

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
  def end_call # rubocop:disable Metrics/MethodLength
    require 'httparty'
    require 'nokogiri'

    url = params[:Location]
    # get everything after the last / in the url
    task_id = File.basename(url)

    cancele_url = "http://198.18.133.43:8080/ccp-webapp/ccp/task/#{task_id}/close"

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

    # task status requsest to check the status of the task before cancelling the task
    response_status = HTTParty.get(url,
                                   basic_auth: { username: 'administrator', password: 'C1sco12345' })

    xml_data = response_status.body

    doc = Nokogiri::XML(xml_data)
    # check the status of the task and take action based on the status
    # if the status is reserved then we need to close the task
    # if doc.at_css('status')&.content == 'reserved' && !doc.at_css('status')&.content.nil?
    #   HTTParty.put(cancele_url,
    #                headers: { 'Content-Type' => 'application/xml' },
    #                basic_auth: { username: 'administrator', password: 'C1sco12345' })
    # elsif doc.at_css('status')&.content == 'queued' && !doc.at_css('status')&.content.nil?
    #   HTTParty.delete(url,
    #                   headers: { 'Content-Type' => 'application/xml' },
    #                   basic_auth: { username: 'administrator', password: 'C1sco12345' })
    # else
    #   p 'task is not reserved or queued'
    # end

    render json: {
      'message': 'meeting ended',
      'Location': url,
      'task_status_url': cancele_url,
      'task_status': doc.at_css('status')&.content,
      'task_id': task_id,
      'task_status_response': response_status,
      'task_status_response_body': response_status.body,
      'task_status_response_code': response_status.code,
      'task_status_response_message': response_status.message

    }, status: :ok
  end

  private

  def set_conversation
    @conversation = create_conversation if conversation.nil?
  end

  def set_message
    @message = @web_widget.inbox.messages.find(permitted_params[:id])
  end

  # creating a uneque and unfined meeting link between the agent and the customer
  def set_meeting_url
    @meeting_name = meeting_url(
      conversation.inbox_id,
      conversation.contact.email,
      conversation.display_id,
      conversation.contact.name
    )
  end

  #   def finesse_request(_auth_token)
  #     auth_length = auth_token.length
  #     #  slice the auth token into 4 segments for the cesco xml can take it
  #     segment_length = auth_length / 4

  #     auth_token_1 = auth_token.slice(0, segment_length.ceil)

  #     auth_token_2 = auth_token.slice(segment_length.ceil, segment_length.ceil)

  #     auth_token_3 = auth_token.slice(segment_length.ceil * 2, segment_length.ceil)

  #     auth_token_4 = auth_token.slice(segment_length.ceil * 3, segment_length.ceil)
  #     require 'httparty'
  #     url = ENV.fetch('CISCO_FINESSE_URL')

  #     xml_body = "
  #     <Task>
  #     <name>John Doe1</name>
  #     <title>Help with not my phone</title>
  #     <description>This is my description</description>
  #     <scriptSelector>CumulusTask</scriptSelector>
  #     <requeueOnRecovery>true</requeueOnRecovery>
  #     <tags>
  #         <tag>phone</tag>
  #         <tag>sss</tag>
  #     </tags>
  #     <variables>
  #         <!-- Below two fields are optional fields.
  #        1) include mediaType to indicate the media type attribute of
  #           POD when it is created.
  #        2) If podRefURL is passed then POD creation will be skipped
  #           for this contact.
  #     <variable><name>mediaType</name><value>chat</value></variable><variable><name>podRefURL</name><value>https://context-service.rciad.ciscoccservice.com/context/
  #       pod/v1/podId/b066c3c0-c346-11e5-b3dd-3f1450b33459</value></variable>  -->
  #       <variable>
  #           <name>cv_1</name>
  #           <value>#{auth_token_1}</value>
  #       </variable>
  #       <variable>
  #             <name>cv_2</name>
  #             <value>#{auth_token_2}</value>
  #       </variable>
  #       <variable>
  #               <name>cv_3</name>
  #               <value>#{auth_token_3}</value>
  #     </variable>
  #     <variable>
  #             <name>cv_4</name>
  #             <value>#{auth_token_4}</value>
  #     </variable>
  #     <variable>
  #         <name>user_(eccVariableName)</name>
  #         <value>eccVariableValue</value>
  #     </variable>
  #     <variable>
  #         <name>anythingElseExtensionFieldName</name>
  #         <value>anythingElseExtensionFieldValue</value>
  #     </variable>
  #   </variables>
  # </Task>
  #     "

  #     HTTParty.post(url,
  #                   body: xml_body,
  #                   headers: { 'Content-Type' => 'application/xml' },
  #                   basic_auth: { username: ENV.fetch('CISCO_FINESSE_USERNAME'),
  #                                 password: ENV.fetch('CISCO_FINESSE_PASSWORD') })
  #   end
end
