import { buildSearchParamsWithLocale } from './urlParamsHelper'

export const createIframe = () => {
    const iframe = document.createElement('iframe');
    iframe.className = 'iframe-popup';
    console.log('iframe', iframe)
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.allow = 'camera; microphone; fullscreen; autoplay';
    iframe.allowFullscreen = true;
    iframe.id = 'iframe';
    //  add gray background to the iframe
    iframe.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
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