<template>
  <div>
    <button class="button join-call-button" color-scheme="secondary" :is-loading="isLoading" :style="{
      background: widgetColor,
      borderColor: widgetColor,
      color: textColor,
    }" @click="joinTheCall">
      <fluent-icon icon="video-add" class="mr-2" />
      {{ $t('INTEGRATIONS.DYTE.CLICK_HERE_TO_JOIN') }}
    </button>
    <!-- <div v-if="isOpen" class="video-call--container">
      <iframe :src="meetingUrl"
        allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;" />
      <button class="button small join-call-button leave-room-button" @click="leaveTheRoom">
        {{ $t('INTEGRATIONS.DYTE.LEAVE_THE_ROOM') }}
      </button>
    </div> -->
  </div>
</template>
<script>
import IntegrationAPIClient from 'widget/api/integration';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { buildJitsiURL } from 'shared/helpers/IntegrationHelper';
import { getContrastingTextColor } from '@chatwoot/utils';
import { mapGetters } from 'vuex';
import { buildSearchParamsWithLocale } from '../../helpers/urlParamsHelper';

// app/javascript/widget/helpers/urlParamsHelper.js
// app/javascript/widget/components/template/IntegrationCard.vue
export default {
  components: {
    FluentIcon,
  },
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
    return { isLoading: false, dyteAuthToken: '', isSDKMounted: false, isOpen: false, meetingUrl: '' };
  },
  computed: {
    ...mapGetters({ widgetColor: 'appConfig/getWidgetColor' }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    meetingLink() {
      return buildDyteURL(this.meetingData.room_name, this.dyteAuthToken);
    },
  },

  methods: {
    async joinTheCall() {
      this.isLoading = true;
      this.isOpen = true;

      try {
        const search = buildSearchParamsWithLocale(window.location.search);
        const baseUrl = window.location.href.split('/').slice(0, 3).join('/');
        const urlLocation = window.location.href;
        const xAuthToken = window.authToken;
        const url = `${baseUrl}/api/v1/widget/jitsi_calls${search}`;
        const os = navigator.platform.split(' ')[0];
        fetch(url, {
          "headers": {
            "accept": "application/json, text/plain, */*",
            "accept-language": "en-US,en;q=0.9,ar;q=0.8",
            "content-type": "application/json",
            "sec-ch-ua": "\"Google Chrome\";v=\"119\", \"Chromium\";v=\"119\", \"Not?A_Brand\";v=\"24\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": `"${os}"`,
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-origin",
            "x-auth-token": xAuthToken,
          },
          "referrer": urlLocation,
          "method": "GET",
          "mode": "cors",
          "credentials": "omit"
        }).then(response => response.json())
          .then(data => {
            console.log(data, '====================');
            this.meetingUrl = data.message.meeting_url
            const iframe = document.createElement('iframe');
            iframe.src = this.meetingUrl;
            iframe.classList.add('iframe-popup'); iframe.allow = "camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;";
            iframe.style.width = '100%';
            iframe.style.height = '100%';
            iframe.style.border = '0';
            iframe.style.position = 'fixed';
            iframe.style.top = '0';
            iframe.style.left = '0';
            iframe.style.bottom = '0';
            iframe.style.right = '0';
            iframe.style.zIndex = '9999';
            iframe.style.boxSizing = 'border-box !important';
            const leaveButton = document.createElement('button');
            // add class to button leave-room-button
            leaveButton.className = 'button small join-call-button leave-room-button';
            leaveButton.innerText = 'Leave The Room';
            leaveButton.style.position = 'absolute';
            leaveButton.style.top = '10px';
            leaveButton.style.right = '100px';
            leaveButton.style.background = '#5145e7';
            leaveButton.style.color = '#fff';
            leaveButton.style.borderColor = '#5145e7';
            leaveButton.style.padding = '1em';
            leaveButton.style.textAlign = 'center';
            leaveButton.style.zIndex = '10000';

            leaveButton.addEventListener('click', this.leaveTheRoom);
            document.body.appendChild(leaveButton);
            document.body.appendChild(iframe);
          })
      } catch (error) {
        // Ignore Error for now
      } finally {
        this.isLoading = false;
      }
    },
    leaveTheRoom() {
      this.dyteAuthToken = '';
      this.isOpen = false;
      // remove iframe
      const iframe = document.querySelector('iframe');
      iframe.parentNode.removeChild(iframe);
      // remove button
      const leaveButton = document.querySelector('.leave-room-button');
      leaveButton.parentNode.removeChild(leaveButton);
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.video-call--container {
  position: fixed;
  width: 100vw;
  height: 100vh;
  top: 0;
  left: 0;
  z-index: 9999;

  iframe {
    width: 100%;
    height: 100%;
    border: 0;
    box-sizing: border-box !important;
  }
}

.join-call-button {
  margin: $space-small 0;
  border-radius: 4px;
  display: flex;
  align-items: center;
}

.leave-room-button {
  position: absolute;
  top: 0;
  right: $space-small;
  background: #145bbe;
}
</style>