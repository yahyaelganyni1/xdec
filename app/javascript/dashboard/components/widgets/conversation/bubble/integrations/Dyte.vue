<template>
  <div>
    <woot-button size="small" variant="smooth" color-scheme="secondary" icon="video-add" class="join-call-button"
      :is-loading="isLoading" @click="joinTheCall">
      {{ $t('INTEGRATION_SETTINGS.DYTE.CLICK_HERE_TO_JOIN') }}
    </woot-button>
    <div v-if="isOpen" class="video-call--container">
      <iframe :src="this.meetingUrl"
        allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;" id="iframe-dyte" />
      <woot-button size="small" variant="smooth" color-scheme="secondary" class="join-call-button" @click="leaveTheRoom">
        {{ $t('INTEGRATION_SETTINGS.DYTE.LEAVE_THE_ROOM') }}
      </woot-button>
      <button class="nudge-btn" @click="nudgeCustomer">
        nudge customer
      </button>
    </div>
  </div>
</template>
<script>
import { buildJitsiURL } from 'shared/helpers/IntegrationHelper';
import alertMixin from 'shared/mixins/alertMixin';
import Auth from '../../../../../api/auth';
import { sendModuleCall } from '../../../../../helper/actionCable'
import { createIframe } from '../../../../../helper/iframeHelper';

export default {
  mixins: [alertMixin],
  props: {
    messageId: {
      type: Number,
      required: true,
    },
    meetingData: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      isLoading: false, dyteAuthToken: '', isSDKMounted: false, isOpen: false, meetingUrl: '',
      inComingCall: false
    };
  },
  computed: {
    meetingLink() {
      return buildJitsiURL()
    },
  },

  methods: {
    createModule() {
      const inComingCallResult = sendModuleCall();
      this.inComingCall = inComingCallResult;
    },
    nudgeCustomer() {
      console.log('nudge customer from Dyte')

      const {
        'access-token': accessToken,
        'token-type': tokenType,
        client,
        expiry,
        uid,
      } = Auth.getAuthData();
      const baseUrl = window.location.href.split('/').slice(0, 3).join('/');
      const accountId = window.location.href.split('/').slice(5, 6).join('/');
      const conversationId = window.location.href.split('/').slice(7, 8).join('/');
      // const fullUrl = `${baseUrl}/api/v1/accounts/${accountId}/conversations/${conversationId}/jitsi_meeting`;
      try {
        const nudgeUrl = `${baseUrl}/api/v1/accounts/${accountId}/conversations/${conversationId}/jitsi_meeting/nudge`
        console.log('nudgeUrl', nudgeUrl)
        fetch(nudgeUrl,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              accept: 'application/json, text/plain, */*',
              'access-token': accessToken,
              'token-type': tokenType,
              client,
              expiry,
              uid,
            }
          })
          .then(response => response.json())
          .then(data => {
            console.log('Nudge message sent');
            console.log(data, '__data__')
          })
          .catch(error => {
            console.error('Error:', error);
            console.log('there was an error sending the nudge message')
          });

      } catch (err) {
        this.showAlert(this.$t('INTEGRATION_SETTINGS.DYTE.NUDGE_ERROR'));
        console.log('there was an error sending the nudge message')
      }
    },
    async joinTheCall() {

      this.isLoading = true;
      this.isOpen = true;
      // const agentName = this.$store.getters["contacts/getCurrentUser"].name
      const agentName = this.$store.getters["agents/getAgents"][0].available_name
      console.log(agentName, '=========agentName===========')
      const {
        'access-token': accessToken,
        'token-type': tokenType,
        client,
        expiry,
        uid,
      } = Auth.getAuthData();
      const baseUrl = window.location.href.split('/').slice(0, 3).join('/');
      const accountId = window.location.href.split('/').slice(5, 6).join('/');
      const conversationId = window.location.href.split('/').slice(7, 8).join('/');
      const fullUrl = `${baseUrl}/api/v1/accounts/${accountId}/conversations/${conversationId}/jitsi_meeting?username=${agentName}`;
      try {
        fetch(fullUrl, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'accept': 'application/json, text/plain, */*',
            'access-token': accessToken,
            'token-type': tokenType,
            client,
            expiry,
            uid,
          }
        })
          .then((response) => response.json())
          .then((data) => {
            this.meetingUrl = data.meeting_url;
            console.log(data, '====================data_+++++++++++++');
          });
      } catch (err) {
        this.showAlert(this.$t('INTEGRATION_SETTINGS.DYTE.JOIN_ERROR'));
      } finally {
        this.isLoading = false;
      }
    },
    leaveTheRoom() {
      this.dyteAuthToken = '';
      this.isOpen = false;
      this.meetingUrl = '';
    },
  },
};
</script>
<style lang="scss">
.join-call-button {
  margin: var(--space-small) 0;
  background-color: #369EFF !important;
  color: #fff !important;
}

.video-call--container {
  position: fixed;
  bottom: 0;
  right: 0;
  width: 100%;
  height: 100%;
  z-index: var(--z-index-high);
  padding: var(--space-smaller);
  background: var(--b-800);

  iframe {
    width: 100%;
    height: 100%;
    border: 0;
  }

  .nudge-btn {
    position: absolute;
    top: 5;
    background-color: green !important;
    color: #fff !important;
    border-radius: 9px;
    padding: .5em 1em;
    left: .6em;
    min-width: 10%;
    max-width: 20%;
    cursor: pointer;
  }

  button {
    position: absolute;
    top: var(--space-smaller);
    right: 10rem;
  }
}
</style>
