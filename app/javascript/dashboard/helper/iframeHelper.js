import Auth from '../api/auth';

export const createIframe = (data) => {
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
        })
        .catch(error => {
            console.error('Error:', error);
        });

    const iframeContainer = document.createElement('div');
    iframeContainer.style.position = 'fixed';
    iframeContainer.style.top = '0';
    iframeContainer.style.left = '0';
    iframeContainer.style.width = '100%';
    iframeContainer.style.height = '100%';
    iframeContainer.style.backgroundColor = 'rgba(55, 55, 55, 1)';
    iframeContainer.style.zIndex = '9999';

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
    leaveButton.style.backgroundColor = 'red';;
    iframe.style.width = '100%';
    iframe.style.height = '100vh';
    iframe.style.border = 'none';
    iframe.allow =
        'camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;';
    iframe.allowFullscreen = true;

    leaveButton.addEventListener('click', () => {
        iframeContainer.remove();
    });


    // nudge button
    const nudgeButton = document.createElement('button');
    nudgeButton.innerText = 'Nudge Customer';
    nudgeButton.style.position = 'fixed';
    nudgeButton.style.top = '10px';
    nudgeButton.style.right = '100px';
    nudgeButton.style.zIndex = '10000';
    nudgeButton.style.padding = '10px';
    nudgeButton.style.border = 'none';
    nudgeButton.style.borderRadius = '5px';
    nudgeButton.style.color = 'white';
    nudgeButton.style.backgroundColor = 'green';
    nudgeButton.style.cursor = 'pointer';
    // style the nudgeButton if disabled


    // nudge event listener
    nudgeButton.addEventListener('click', () => {
        console.log('Nudge Customer');


        const nudgeUrl = `${baseUrl}/api/v1/accounts/${accountId}/conversations/${conversationId}/jitsi_meeting/nudge`
        console.log('nudgeUrl', nudgeUrl)
        // create the nudge message
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
            });


    });
    iframeContainer.appendChild(nudgeButton);



    iframeContainer.appendChild(leaveButton);
    iframeContainer.appendChild(iframe);
    document.body.appendChild(iframeContainer);
};