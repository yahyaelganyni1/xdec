<template>
    <div>
        <button class="join-call-button" :is-loading="isLoading" @click="joinTheCall">
            <fluent-icon icon="video-add" class="join-call-button__icon" />
            Start Video Call
        </button>
        <div v-if="isOpen" class="video-call--container">
            <iframe :src="this.meetingUrl"
                allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;" />
            <button class="leave-call-button" @click="leaveTheRoom">
                leave the room
            </button>
        </div>
    </div>
</template>
<script>
import { buildDyteURL } from 'shared/helpers/IntegrationHelper';
import alertMixin from 'shared/mixins/alertMixin';
import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper'
import FluentIcon from '../../shared/components/FluentIcon/DashboardIcon.vue'
// app/javascript/shared/components/FluentIcon/DashboardIcon.vue
// app/javascript/widget/components/JitsiCall.vue

export default {
    name: 'JitsiCall',
    components: {
        FluentIcon,
    },
    mixins: [alertMixin],
    props: {
        meetingData: {
            type: Object,
            default: () => ({}),
        },
    },
    data() {
        return { isLoading: false, dyteAuthToken: '', isSDKMounted: false, isOpen: false, meetingUrl: '' };
    },
    computed: {
        meetingLink() {
            return buildDyteURL(this.meetingData.room_name, this.dyteAuthToken);
        },
    },
    methods: {

        async joinTheCall() {
            this.isLoading = true;
            try {
                const search = buildSearchParamsWithLocale(window.location.search);
                const baseUrl = window.location.href.split('/').slice(0, 3).join('/');
                const urlLocation = window.location.href;
                const xAuthToken = window.authToken;
                const url = `${baseUrl}/api/v1/widget/jitsi_calls${search}`;
                const os = navigator.platform.split(' ')[0];

                console.log('os====', os);

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
                    "method": "POST",
                    "mode": "cors",
                    "credentials": "omit"
                }).then(response => response.json())
                    .then(data => {
                        this.meetingUrl = data.message.meeting_url
                        this.isOpen = true;
                    })
            } catch (err) {
                this.showAlert(this.$t('INTEGRATION_SETTINGS.DYTE.JOIN_ERROR'));
            } finally {
                this.isLoading = false;
            }
        },
        leaveTheRoom() {
            this.dyteAuthToken = '';
            this.isOpen = false;
        },
    },
};
</script>
<style lang="scss">
.join-call-button {
    color: #fff;
    margin: var(--space-small) 0;
    cursor: pointer;
    background-color: #1f93ff;
    padding: .5em 1em;
    border-radius: 9px;
}

.join-call-button__icon {
    display: inline-block;
    margin-right: 0.5em;
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

    .leave-call-button {
        position: absolute;
        top: 1em;
        right: 4em;
        background-color: #5145e7;
        color: rgb(255, 255, 255);
        border-radius: 9px;
        font-size: .8em;
        padding: .5em 1em;
    }
}
</style>
