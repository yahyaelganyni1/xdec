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
import { createIframe } from '../../helpers/iframePopup';

// app/javascript/widget/helpers/iframePopup.js
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
      console.log(this.meetingData, '=========meetingData===========')
      const username = this.$store.getters["contacts/getCurrentUser"].name
      try {
        createIframe(this.meetingLink, username)
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