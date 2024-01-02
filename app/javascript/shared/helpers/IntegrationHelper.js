const DYTE_MEETING_LINK = 'https://app.dyte.in/meeting/stage/';
const JITSI_MEETING_LINK = 'https://jitsi.xdec.io/';

export const buildDyteURL = (roomName, dyteAuthToken) => {
  return `${DYTE_MEETING_LINK}${roomName}?authToken=${dyteAuthToken}&showSetupScreen=true&disableVideoBackground=true`;
};

export const buildJitsiURL = roomName => {
  console.log('room name', roomName)
  return `${JITSI_MEETING_LINK}${roomName}`;
};
