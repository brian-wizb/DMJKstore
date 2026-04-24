const fs = require('fs');
const path = require('path');

const source = path.join(__dirname, '..', 'web', 'firebase-messaging-sw.js');
const destination = path.join(__dirname, '..', 'build', 'web', 'firebase-messaging-sw.js');

if (!fs.existsSync(source)) {
  throw new Error('Missing source file: web/firebase-messaging-sw.js');
}

fs.mkdirSync(path.dirname(destination), { recursive: true });
fs.copyFileSync(source, destination);

console.log('Copied firebase-messaging-sw.js to build/web');
