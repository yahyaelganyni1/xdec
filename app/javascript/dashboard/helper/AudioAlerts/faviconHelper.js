export const showBadgeOnFavicon = () => {
  const favicons = document.querySelectorAll('.favicon');

  favicons.forEach(favicon => {
    const newFileName = `/xDEC.png`;
    favicon.href = newFileName;
  });
};

export const initFaviconSwitcher = () => {
  const favicons = document.querySelectorAll('.favicon');

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      favicons.forEach(favicon => {
        const oldFileName = `/xDEC.png`;
        favicon.href = oldFileName;
      });
    }
  });
};
