/* global axios */
import ApiClient from '../ApiClient';

class MicrosoftClient extends ApiClient {
  constructor() {
    super('microsoft', { accountScoped: true });
  }

  generateAuthorization(payload) {
    console.log("payload", payload)
    return axios.post(`${this.url}/authorization`, payload);
  }
}

export default new MicrosoftClient();
