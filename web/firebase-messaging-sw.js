importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCWvoIK9DX9HILupH6fsjKJfelDvD9grmo',
  authDomain: 'makyaraforum.firebaseapp.com',
  projectId: 'makyaraforum',
  storageBucket: 'makyaraforum.appspot.com',
  messagingSenderId: '688885675400',
  appId: '1:688885675400:web:b3516bf9449aee3827b63d',
  measurementId: 'G-SLHK60E7P3',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const title = notification.title || 'DMJK Store';
  const options = {
    body: notification.body || '',
    icon: '/icons/Icon-192.png',
  };

  self.registration.showNotification(title, options);
});
