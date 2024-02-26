<template>
    <div>
        <button v-if="!fromTheInput" class="join-call-button" :is-loading="isLoading" @click="joinTheCall"
            :style="{ backgroundColor: this.widgetColor }">
            <fluent-icon icon="video-add" class="join-call-button__icon" />
            Start Video Call
        </button>
        <button v-if="fromTheInput" @click="joinTheCall">
            <fluent-icon icon="video-add" class="join-call-button__icon" />
        </button>
        <div v-if="isOpen" class="video-call--container" id="videoCallContainer">
            <!-- <iframe :src="this.meetingUrl"
                allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;" /> -->
            <div class="loading" v-if="isLoading">
                <div class="lds-facebook">
                    <div></div>
                    <div></div>
                    <div></div>
                </div>
                Waiting for agent to join...
            </div>
            <button class="leave-call-button" @click="leaveTheRoom">
                Cancel Call
            </button>
        </div>
    </div>
</template>
<script>
import { buildDyteURL } from 'shared/helpers/IntegrationHelper';
import alertMixin from 'shared/mixins/alertMixin';
import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper'
import FluentIcon from '../../shared/components/FluentIcon/DashboardIcon.vue'
import { tr } from 'date-fns/locale';
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
        widgetColor: {
            type: String,
            default: '#1f93ff'
        },
        fromTheInput: {
            type: Boolean,
            default: false,
        },

    },
    data() {
        return { isLoading: false, dyteAuthToken: '', isSDKMounted: false, isOpen: false, meetingUrl: '', taskLocation: '' };
    },
    computed: {
        meetingLink() {
            return buildDyteURL(this.meetingData.room_name, this.dyteAuthToken);
        },
    },
    methods: {

        async joinTheCall() {
            this.isLoading = true;
            console.log('this.meetingData====', this.meetingData);
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
                    "method": "POST",
                    "mode": "cors",
                    "credentials": "omit"
                }).then(response => response.json())
                    .then(data => {
                        this.meetingUrl = data.message.meeting_url
                        // const taskId = data.message.task_id;
                        this.taskLocation = data.message.task_location;
                        console.log('meeting has been created successfully', data.message.meeting_url);
                        console.log(data.message.task_location, 'task_location');
                        this.isOpen = true;
                    })
            } catch (err) {
                this.showAlert(this.$t('INTEGRATION_SETTINGS.DYTE.JOIN_ERROR'));
            } finally {
                this.isLoading = true;
            }
        },
        leaveTheRoom() {
            this.dyteAuthToken = '';
            this.isOpen = false;
            // try {
            //     const search = buildSearchParamsWithLocale(window.location.search);
            //     const baseUrl = window.location.href.split('/').slice(0, 3).join('/');
            //     const urlLocation = window.location.href;
            //     const xAuthToken = window.authToken;
            //     const url = `${baseUrl}/api/v1/widget/jitsi_calls/end_call${search}`;
            //     const os = navigator.platform.split(' ')[0];
            //     console.log(url, 'url')
            //     console.log(this.taskLocation, 'taskLocation')
            //     console.log('==--leave the room--==')
            //     fetch(url,

            //         {
            //             "headers": {
            //                 "accept": "application/json, text/plain, */*",
            //                 "accept-language": "en-US,en;q=0.9,ar;q=0.8",
            //                 "content-type": "application/json",
            //                 "sec-ch-ua": "\"Google Chrome\";v=\"119\", \"Chromium\";v=\"119\", \"Not?A_Brand\";v=\"24\"",
            //                 "sec-ch-ua-mobile": "?0",
            //                 "sec-ch-ua-platform": `"${os}"`,
            //                 "sec-fetch-dest": "empty",
            //                 "sec-fetch-mode": "cors",
            //                 "sec-fetch-site": "same-origin",
            //                 "x-auth-token": xAuthToken,
            //             },
            //             "body": JSON.stringify({ task_location: this.taskLocation }),
            //             "referrer": urlLocation,
            //             "method": "DELETE",
            //             "mode": "cors",
            //             "credentials": "omit",
            //             "body": JSON.stringify({ "Location": this.taskLocation })
            //         }).then(response => response.json())
            //         .then(data => {
            //             console.log('meeting has been ended successfully', data);
            //             this.isOpen = false;
            //         })
            // } catch (error) {
            //     console.log('error', error);
            // }

        },
    },
};
</script>
<style lang="scss">
.join-call-button {
    color: #fff;
    margin: var(--space-small) 0;
    cursor: pointer;
    //background-color: #1f93ff;
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

    .loading {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        color: #fff;
        font-size: 1.5em;
        text-align: center;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        z-index: var(--z-index-high);
    }

    .leave-call-button {

        position: fixed;
        top: 10px;
        right: 10px;
        z-index: 10000;
        padding: 10px;
        border: none;
        border-radius: 5px;
        color: white;
        background-color: red;

    }

    .lds-facebook {
        display: inline-block;
        position: relative;
        width: 80px;
        height: 80px;
    }

    .lds-facebook div {
        display: inline-block;
        position: absolute;
        left: 8px;
        width: 16px;
        background: #fff;
        animation: lds-facebook 1.2s cubic-bezier(0, 0.5, 0.5, 1) infinite;
    }

    .lds-facebook div:nth-child(1) {
        left: 8px;
        animation-delay: -0.24s;
    }

    .lds-facebook div:nth-child(2) {
        left: 32px;
        animation-delay: -0.12s;
    }

    .lds-facebook div:nth-child(3) {
        left: 56px;
        animation-delay: 0;
    }

    @keyframes lds-facebook {
        0% {
            top: 8px;
            height: 64px;
        }

        50%,
        100% {
            top: 24px;
            height: 32px;
        }
    }

}
</style>
