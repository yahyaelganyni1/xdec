import { buildSearchParamsWithLocale } from './urlParamsHelper'
const iframe = document.createElement('iframe');

export const shake = (element, duration = 70, intensity = 25, iterations = 6) => {
    // Get original position for accurate return
    const originalPosition = element.getBoundingClientRect();

    // Get the viewport dimensions
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

    // Create the keyframes
    const keyframes = [
        { transform: `translate(${intensity}px, ${intensity}px)` },
        { transform: `translate(-${intensity}px, -${intensity}px)` },
        { transform: `translate(-${intensity}px, ${intensity}px)` },
        { transform: `translate(${intensity}px, -${intensity}px)` },
    ];

    // Create the timing options
    const timing = {
        duration,
        iterations,
    };

    // Create the animation
    const animation = element.animate(keyframes, timing);

    // When the animation is complete, return the element to its original position
    animation.onfinish = () => {
        element.style.transform = `translate(${originalPosition.left}px, ${originalPosition.top}px)`;
    };

    // Return the animation

    return animation;
}

export const createIframe = (data, customerName = 'client') => {
    const iframeContainer = document.createElement('div');
    iframe.className = 'iframe-popup';
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
    const username = customerName
    const url = `${baseUrl}/api/v1/widget/jitsi_calls${search}&username=${username}`;
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
            const meetingUrl = data.message.meeting_url;
            iframe.src = meetingUrl;
        });
    // Set the position and z-index of the iframe
    iframeContainer.style.position = 'fixed';
    iframeContainer.style.top = '0';
    iframeContainer.style.left = '0';
    iframeContainer.style.width = '100%';
    iframeContainer.style.height = '100%';
    iframeContainer.style.backgroundColor = 'rgba(55, 55, 55, 1)';
    iframeContainer.style.zIndex = '9999';
    iframeContainer.id = 'iframeContainer';
    iframeContainer.appendChild(iframe);



    // Append the iframe to the body of the document
    document.body.appendChild(iframeContainer);

    // Create the leave button
    const leaveButton = document.createElement('button');
    // ! the remove button with be removed after we implement from agent side
    const alertButton = document.createElement('button');

    document.body.appendChild(leaveButton);

    leaveButton.innerText = 'Leave Call';
    leaveButton.style.position = 'fixed';
    leaveButton.style.top = '15px';
    leaveButton.style.right = '70px';
    leaveButton.style.zIndex = '10000';
    leaveButton.style.padding = '10px';
    leaveButton.style.border = 'none';
    leaveButton.style.borderRadius = '5px';
    leaveButton.style.color = 'white';
    leaveButton.style.backgroundColor = 'red';
    // Add event listener to remove the iframe when the button is clicked
    leaveButton.addEventListener('click', () => {
        // Remove the iframe from the dom
        // document.body.removeChild(iframe);
        // document.body.removeChild(leaveButton);
        // document.body.removeChild(alertButton);
        iframeContainer.remove();
        // remove the videoCallContainer if it exists from the dom
        const videoCallContainer = document.getElementById('videoCallContainer');
        if (videoCallContainer) {
            videoCallContainer.remove();
            // reload the page
            window.location.reload();

        }
    });

    // Append the leave button to the body of the document
    iframeContainer.appendChild(leaveButton);

    // Create the alert button
    alertButton.innerText = 'Alert';
    alertButton.style.position = 'fixed';
    alertButton.style.bottom = '10px';
    alertButton.style.left = '10px';
    alertButton.style.zIndex = '10000';
    alertButton.style.padding = '10px';
    alertButton.style.border = 'none';
    alertButton.style.borderRadius = '5px';
    alertButton.style.color = 'white';
    alertButton.style.backgroundColor = 'blue';
    // Add event listener to trigger the alert
    // Set the z-index of the alert button
    alertButton.style.zIndex = '10001';

    // Set the z-index of the body
    document.body.style.zIndex = '10000';

    // append the al
    // Add event listener to trigger the alert
    alertButton.addEventListener('click', () => {

        shake(iframe);
    });
    // Append the alert button to the body of the document
    // document.body.appendChild(alertButton);
};


