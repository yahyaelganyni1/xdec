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
    return axios.post(`${this.url}/jitsi_meeting`, {
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
