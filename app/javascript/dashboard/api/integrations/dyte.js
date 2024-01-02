/* global axios */

import ApiClient from '../ApiClient';

class DyteAPI extends ApiClient {
  constructor() {
    super('integrations/dyte', { accountScoped: true });
  }

  createAMeeting(conversationId) {
    return axios.post(`${this.url}/create_a_meeting`, {
      conversation_id: conversationId,
    });
  }

  createJitsiMeeting(conversationId) {
    console.log("jitsi meeting has fired", conversationId)
    console.log('url', this.url)
    // replace /dyte from this.url with /jitsi_meeting_agents

    const newUrl = this.url.replace('/dyte', '/jitsi_meeting_agents')
    console.log('new url', newUrl)
    return axios.post(newUrl, {
      conversation_id: conversationId,
    });
  }

  addParticipantToMeeting(messageId) {
    return axios.post(`${this.url}/add_participant_to_meeting`, {
      message_id: messageId,
    });
  }
}

export default new DyteAPI();
