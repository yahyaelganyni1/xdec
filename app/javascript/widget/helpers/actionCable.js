import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';
import { playNewMessageNotificationInWidget } from 'widget/helpers/WidgetAudioNotificationHelper';
import { ON_AGENT_MESSAGE_RECEIVED } from '../constants/widgetBusEvents';
import { IFrameHelper } from 'widget/helpers/utils';
import { shouldTriggerMessageUpdateEvent } from './IframeEventHelper';
import { CHATWOOT_ON_MESSAGE } from '../constants/sdkEvents';
import { buildSearchParamsWithLocale } from './urlParamsHelper'

// app/javascript/widget/helpers/urlParamsHelper.js
// app/javascript/widget/helpers/actionCable.js


const isMessageInActiveConversation = (getters, message) => {
  const { conversation_id: conversationId } = message;
  const activeConversationId =
    getters['conversationAttributes/getConversationParams'].id;
  return activeConversationId && conversationId !== activeConversationId;
};

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    super(app, pubsubToken);
    this.events = {
      'message.created': this.onMessageCreated,
      'message.updated': this.onMessageUpdated,
      'conversation.typing_on': this.onTypingOn,
      'conversation.typing_off': this.onTypingOff,
      'conversation.status_changed': this.onStatusChange,
      'conversation.created': this.onConversationCreated,
      'presence.update': this.onPresenceUpdate,
      'contact.merged': this.onContactMerge,
    };
  }

  onDisconnected = () => {
    this.setLastMessageId();
  };

  onReconnect = () => {
    this.syncLatestMessages();
  };

  setLastMessageId = () => {
    this.app.$store.dispatch('conversation/setLastMessageId');
  };

  syncLatestMessages = () => {
    this.app.$store.dispatch('conversation/syncLatestMessages');
  };

  onStatusChange = data => {
    if (data.status === 'resolved') {
      this.app.$store.dispatch('campaign/resetCampaign');
    }
    this.app.$store.dispatch('conversationAttributes/update', data);
  };

  onMessageCreated = data => {
    console.log(data)
    const videoCallContainer = document.querySelector('.video-call--container');
    console.log('videoCallContainer', videoCallContainer)
    const popupIframe = document.querySelectorAll('.iframe-popup');
    // console.log('popupIframe', popupIframe)
    if (
      data.content_type === 'integrations' &&
      data.message_type === 1 &&
      data.content.includes('accepted the video call') &&
      // videoCallContainer
      popupIframe.length === 0
      // assigneeId === currentUserId
    ) {
      // if (videoCallContainer) {
      //   videoCallContainer.style.display = 'none';
      // }
      const createIframe = () => {
        const iframe = document.createElement('iframe');
        iframe.className = 'iframe-popup';
        console.log('iframe', iframe)
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.allow = 'camera; microphone; fullscreen; autoplay';
        iframe.allowFullscreen = true;
        iframe.id = 'iframe';

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
            this.meetingUrl = data.message.meeting_url;
            console.log('meetingUrl====', data.message.meeting_url);
            this.isOpen = true;
            // Access the iframe src here
            const iframeSrc = this.meetingUrl;
            console.log('iframeSrc', iframeSrc)
            // Use the iframeSrc as needed
            iframe.src = iframeSrc;
          });
        // Set the position and z-index of the iframe
        iframe.style.position = 'fixed';
        iframe.style.top = '0';
        iframe.style.left = '0';
        iframe.style.zIndex = '9999';

        // Append the iframe to the body of the document
        document.body.appendChild(iframe);

        // Create the leave button
        const leaveButton = document.createElement('button');
        leaveButton.innerText = 'Leave Call';
        leaveButton.style.position = 'fixed';
        leaveButton.style.top = '10px';
        leaveButton.style.right = '10px';
        leaveButton.style.zIndex = '10000';
        leaveButton.style.padding = '10px';
        leaveButton.style.border = 'none';
        leaveButton.style.borderRadius = '5px';
        leaveButton.style.color = 'white';
        leaveButton.style.backgroundColor = 'red';
        // Add event listener to remove the iframe when the button is clicked
        leaveButton.addEventListener('click', () => {
          // Remove the iframe from the dom
          document.body.removeChild(iframe);
          document.body.removeChild(leaveButton);
          // remove the videoCallContainer if it exists from the dom
          const videoCallContainer = document.getElementById('videoCallContainer');
          if (videoCallContainer) {
            videoCallContainer.remove();
            // reload the page
            window.location.reload();

          }
        });

        // Append the leave button to the body of the document
        document.body.appendChild(leaveButton);
      };

      // Call the createIframe function wherever you want to create the iframe
      createIframe();
    }

    if (isMessageInActiveConversation(this.app.$store.getters, data)) {
      return;
    }

    this.app.$store
      .dispatch('conversation/addOrUpdateMessage', data)
      .then(() => window.bus.$emit(ON_AGENT_MESSAGE_RECEIVED));

    IFrameHelper.sendMessage({
      event: 'onEvent',
      eventIdentifier: CHATWOOT_ON_MESSAGE,
      data,
    });
    if (data.sender_type === 'User') {
      playNewMessageNotificationInWidget();
    }
  };

  onMessageUpdated = data => {
    if (isMessageInActiveConversation(this.app.$store.getters, data)) {
      return;
    }

    if (shouldTriggerMessageUpdateEvent(data)) {
      IFrameHelper.sendMessage({
        event: 'onEvent',
        eventIdentifier: CHATWOOT_ON_MESSAGE,
        data,
      });
    }

    this.app.$store.dispatch('conversation/addOrUpdateMessage', data);
  };

  onConversationCreated = () => {
    this.app.$store.dispatch('conversationAttributes/getAttributes');
  };

  onPresenceUpdate = data => {
    this.app.$store.dispatch('agent/updatePresence', data.users);
  };

  // eslint-disable-next-line class-methods-use-this
  onContactMerge = data => {
    const { pubsub_token: pubsubToken } = data;
    ActionCableConnector.refreshConnector(pubsubToken);
  };

  onTypingOn = data => {
    const activeConversationId =
      this.app.$store.getters['conversationAttributes/getConversationParams']
        .id;
    const isUserTypingOnAnotherConversation =
      data.conversation && data.conversation.id !== activeConversationId;

    if (isUserTypingOnAnotherConversation || data.is_private) {
      return;
    }
    this.clearTimer();
    this.app.$store.dispatch('conversation/toggleAgentTyping', {
      status: 'on',
    });
    this.initTimer();
  };

  onTypingOff = () => {
    this.clearTimer();
    this.app.$store.dispatch('conversation/toggleAgentTyping', {
      status: 'off',
    });
  };

  clearTimer = () => {
    if (this.CancelTyping) {
      clearTimeout(this.CancelTyping);
      this.CancelTyping = null;
    }
  };

  initTimer = () => {
    // Turn off typing automatically after 30 seconds
    this.CancelTyping = setTimeout(() => {
      this.onTypingOff();
    }, 30000);
  };
}

export default ActionCableConnector;
