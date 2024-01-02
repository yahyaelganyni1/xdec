import AuthAPI from '../api/auth';
import BaseActionCableConnector from '../../shared/helpers/BaseActionCableConnector';
import DashboardAudioNotificationHelper from './AudioAlerts/DashboardAudioNotificationHelper';
// /components/widgets/conversation/bubble/integrations/Dyte.vue'
import Auth from '../api/auth';
// app/javascript/dashboard/api/auth.js
// app/javascript/dashboard/helper/actionCable.js
export const sendModuleCall = data => {
  return {
    type: 'sendModuleCall',
    payload: data,
    newCall: !!data,
  };
};

class ActionCableConnector extends BaseActionCableConnector {
  constructor(app, pubsubToken) {
    const { websocketURL = '' } = window.chatwootConfig || {};
    super(app, pubsubToken, websocketURL);
    this.CancelTyping = [];
    this.events = {
      'message.created': this.onMessageCreated,
      'message.updated': this.onMessageUpdated,
      'conversation.created': this.onConversationCreated,
      'conversation.status_changed': this.onStatusChange,
      'user:logout': this.onLogout,
      'page:reload': this.onReload,
      'assignee.changed': this.onAssigneeChanged,
      'conversation.typing_on': this.onTypingOn,
      'conversation.typing_off': this.onTypingOff,
      'conversation.contact_changed': this.onConversationContactChange,
      'presence.update': this.onPresenceUpdate,
      'contact.deleted': this.onContactDelete,
      'contact.updated': this.onContactUpdate,
      'conversation.mentioned': this.onConversationMentioned,
      'notification.created': this.onNotificationCreated,
      'first.reply.created': this.onFirstReplyCreated,
      'conversation.read': this.onConversationRead,
      'conversation.updated': this.onConversationUpdated,
      'account.cache_invalidated': this.onCacheInvalidate,
    };
  }

  onReconnect = () => {
    this.syncActiveConversationMessages();
  };

  onDisconnected = () => {
    this.setActiveConversationLastMessageId();
  };

  setActiveConversationLastMessageId = () => {
    const {
      params: { conversation_id },
    } = this.app.$route;
    if (conversation_id) {
      this.app.$store.dispatch('setConversationLastMessageId', {
        conversationId: Number(conversation_id),
      });
    }
  };

  syncActiveConversationMessages = () => {
    const {
      params: { conversation_id },
    } = this.app.$route;
    if (conversation_id) {
      this.app.$store.dispatch('syncActiveConversationMessages', {
        conversationId: Number(conversation_id),
      });
    }
  };

  isAValidEvent = data => {
    return this.app.$store.getters.getCurrentAccountId === data.account_id;
  };

  onMessageUpdated = data => {
    this.app.$store.dispatch('updateMessage', data);
  };

  onPresenceUpdate = data => {
    this.app.$store.dispatch('contacts/updatePresence', data.contacts);
    this.app.$store.dispatch('agents/updatePresence', data.users);
    this.app.$store.dispatch('setCurrentUserAvailability', data.users);
  };

  onConversationContactChange = payload => {
    const { meta = {}, id: conversationId } = payload;
    const { sender } = meta || {};
    if (conversationId) {
      this.app.$store.dispatch('updateConversationContact', {
        conversationId,
        ...sender,
      });
    }
  };

  onAssigneeChanged = payload => {
    const { id } = payload;
    if (id) {
      this.app.$store.dispatch('updateConversation', payload);
    }
    this.fetchConversationStats();
  };

  onConversationCreated = data => {
    this.app.$store.dispatch('addConversation', data);
    this.fetchConversationStats();
  };

  onConversationRead = data => {
    this.app.$store.dispatch('updateConversation', data);
  };

  // eslint-disable-next-line class-methods-use-this
  onLogout = () => AuthAPI.logout();


  onMessageCreated = data => {
    console.log('data', data)
    const popupModalClass = document.querySelector('.popup-modal');
    const openIframes = document.querySelectorAll('iframe');
    if (
      data.content_type === 'integrations' &&
      data.message_type === 0 &&
      data.content.includes('has started a video call') &&
      !popupModalClass &&
      openIframes.length === 0
    ) {

      const audio = new Audio('/hangouts_video_call.mp3');

      audio.loop = true;
      audio.play();

      const popupModal = document.createElement('div');
      popupModal.classList.add('popup-modal');
      popupModal.innerHTML = `
        <div class="popup-content">
          <p style="font-size: 20px; font-weight: 600;">
            incoming call from ${data.content.split(' ')[0]}
          </p>
          <button id="acceptCallBtn">Accept</button>
          <button id="closeModalBtn" title="cancel call">X</button>
        </div>
      `;


      document.body.appendChild(popupModal);
      const closeModalBtn = document.getElementById('closeModalBtn');
      closeModalBtn.addEventListener('click', () => {
        popupModal.remove();
        audio.pause();
      });

      const acceptCallBtn = document.getElementById('acceptCallBtn');

      acceptCallBtn.style.cursor = 'pointer';
      acceptCallBtn.style.marginRight = '10px';
      acceptCallBtn.style.marginLeft = '10px';
      acceptCallBtn.style.backgroundColor = '#0D3868';
      acceptCallBtn.style.color = '#fff';
      acceptCallBtn.style.padding = '10px';
      acceptCallBtn.style.borderRadius = '5px';

      acceptCallBtn.addEventListener('click', () => {
        popupModal.remove();
        audio.pause();
        const {
          'access-token': accessToken,
          'token-type': tokenType,
          client,
          expiry,
          uid,
        } = Auth.getAuthData();
        const baseUrl = window.location.href.split('/').slice(0, 3).join('/');
        const accountId = data.account_id;
        const conversationId = data.conversation_id;
        const fullUrl = `${baseUrl}/api/v1/accounts/${accountId}/conversations/${conversationId}/jitsi_meeting`;
        const iframe = document.createElement('iframe');
        iframe.classList.add('video-call-iframe');


        fetch(fullUrl, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            accept: 'application/json, text/plain, */*',
            'access-token': accessToken,
            'token-type': tokenType,
            client,
            expiry,
            uid,
          },
        })
          .then(response => response.json())
          .then(data => {
            iframe.src = data.meeting_url;
            audio.pause();
          })
          .catch(error => {
            console.error('Error:', error);
            audio.pause();
          });

        const iframeContainer = document.createElement('div');
        iframeContainer.style.position = 'fixed';
        iframeContainer.style.top = '0';
        iframeContainer.style.left = '0';
        iframeContainer.style.width = '100%';
        iframeContainer.style.height = '100%';
        iframeContainer.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
        iframeContainer.style.zIndex = '9999';

        const iframeCloseButton = document.createElement('button');
        iframeCloseButton.innerText = 'Leave the room';
        iframeCloseButton.style.position = 'absolute';
        iframeCloseButton.style.top = '10px';
        iframeCloseButton.style.right = '15em';
        iframeCloseButton.style.backgroundColor = '#0D3868';
        iframeCloseButton.style.color = '#fff';
        iframeCloseButton.style.padding = '10px';
        iframeCloseButton.style.border = 'none';
        iframeCloseButton.style.borderRadius = '5px';
        iframeCloseButton.style.cursor = 'pointer';
        iframeCloseButton.style.borderRadius = '9px';
        iframe.style.width = '100%';
        iframe.style.height = '100vh';
        iframe.style.border = 'none';
        iframe.allow =
          'camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;';
        iframe.allowFullscreen = true;

        iframeCloseButton.addEventListener('click', () => {
          iframeContainer.remove();
        });

        iframeContainer.appendChild(iframeCloseButton);
        iframeContainer.appendChild(iframe);
        document.body.appendChild(iframeContainer);
      });

      closeModalBtn.style.position = 'absolute';
      closeModalBtn.style.top = '10px';
      closeModalBtn.style.right = '10px';
      closeModalBtn.style.backgroundColor = '#0D3868';
      closeModalBtn.style.color = '#fff';
      closeModalBtn.style.padding = '10px';
      closeModalBtn.style.borderRadius = '5px';

      const WIDTH = window.innerWidth;

      popupModal.style.display = 'flex';
      popupModal.style.justifyContent = 'center';
      popupModal.style.alignItems = 'center';
      popupModal.style.position = 'fixed';
      popupModal.style.top = '50%';
      popupModal.style.left = '50%';
      popupModal.style.transform = 'translate(-50%, -50%)';
      popupModal.style.width = WIDTH > 800 ? '40%' : '80%';
      popupModal.style.height = '40%';
      popupModal.style.backgroundColor = '#fff';
      popupModal.style.zIndex = '1';
      popupModal.style.borderRadius = '9px';
      popupModal.style.boxShadow = '0 0 15px rgba(0, 0, 0, 0.1)';
      popupModal.style.padding = '20px';
      popupModal.style.textAlign = 'center';
      popupModal.style.flexDirection = 'column';

      const popupButtons = popupModal.querySelectorAll('button');
      popupButtons.forEach(button => {
        button.style.cursor = 'pointer';
      });
      // Close the popupModal when clicking outside of it
      document.addEventListener('click', event => {
        if (!popupModal.contains(event.target)) {
          popupModal.remove();
          audio.pause();
        }
      });
    }
    const {
      conversation: { last_activity_at: lastActivityAt },
      conversation_id: conversationId,
    } = data;
    DashboardAudioNotificationHelper.onNewMessage(data);
    this.app.$store.dispatch('addMessage', data);
    this.app.$store.dispatch('updateConversationLastActivity', {
      lastActivityAt,
      conversationId,
    });
  };

  // eslint-disable-next-line class-methods-use-this
  onReload = () => window.location.reload();

  onStatusChange = data => {
    this.app.$store.dispatch('updateConversation', data);
    this.fetchConversationStats();
  };

  onConversationUpdated = data => {
    this.app.$store.dispatch('updateConversation', data);
    this.fetchConversationStats();
  };

  onTypingOn = ({ conversation, user }) => {
    const conversationId = conversation.id;

    this.clearTimer(conversationId);
    this.app.$store.dispatch('conversationTypingStatus/create', {
      conversationId,
      user,
    });
    this.initTimer({ conversation, user });
  };

  onTypingOff = ({ conversation, user }) => {
    const conversationId = conversation.id;

    this.clearTimer(conversationId);
    this.app.$store.dispatch('conversationTypingStatus/destroy', {
      conversationId,
      user,
    });
  };

  onConversationMentioned = data => {
    this.app.$store.dispatch('addMentions', data);
  };

  clearTimer = conversationId => {
    const timerEvent = this.CancelTyping[conversationId];

    if (timerEvent) {
      clearTimeout(timerEvent);
      this.CancelTyping[conversationId] = null;
    }
  };

  initTimer = ({ conversation, user }) => {
    const conversationId = conversation.id;
    // Turn off typing automatically after 30 seconds
    this.CancelTyping[conversationId] = setTimeout(() => {
      this.onTypingOff({ conversation, user });
    }, 30000);
  };

  // eslint-disable-next-line class-methods-use-this
  fetchConversationStats = () => {
    bus.$emit('fetch_conversation_stats');
    bus.$emit('fetch_overview_reports');
  };

  onContactDelete = data => {
    this.app.$store.dispatch(
      'contacts/deleteContactThroughConversations',
      data.id
    );
    this.fetchConversationStats();
  };

  onContactUpdate = data => {
    this.app.$store.dispatch('contacts/updateContact', data);
  };

  onNotificationCreated = data => {
    this.app.$store.dispatch('notifications/addNotification', data);
  };

  // eslint-disable-next-line class-methods-use-this
  onFirstReplyCreated = () => {
    bus.$emit('fetch_overview_reports');
  };

  onCacheInvalidate = data => {
    const keys = data.cache_keys;
    this.app.$store.dispatch('labels/revalidate', { newKey: keys.label });
    this.app.$store.dispatch('inboxes/revalidate', { newKey: keys.inbox });
    this.app.$store.dispatch('teams/revalidate', { newKey: keys.team });
  };
}

export default {
  init(pubsubToken) {
    return new ActionCableConnector(window.WOOT, pubsubToken);
  },
};
