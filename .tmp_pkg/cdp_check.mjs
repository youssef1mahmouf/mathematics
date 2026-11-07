// One-off smoke test: drives headless Chrome over CDP and reports
// (a) console errors, (b) the list of IndexedDB databases after the Flutter
// app booted. Verifies sqflite_common_ffi_web really opened/persisted a DB.
import { spawn } from 'node:child_process';

const CHROME =
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const URL = 'http://127.0.0.1:8181/';
const PROFILE =
  'D:\\Linux-Transfer\\Code\\ECU WEB\\mathematics\\.tmp_pkg\\cdp-profile';
const PORT = 9223;

const chrome = spawn(CHROME, [
  '--headless=new',
  '--disable-gpu',
  '--no-sandbox',
  `--user-data-dir=${PROFILE}`,
  `--remote-debugging-port=${PORT}`,
  '--window-size=1280,900',
  URL,
], { stdio: 'ignore' });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function targets() {
  for (let i = 0; i < 60; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${PORT}/json`);
      const list = await res.json();
      const page = list.find((t) => t.type === 'page');
      if (page) return page;
    } catch {}
    await sleep(500);
  }
  throw new Error('no CDP target');
}

const page = await targets();
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));

let id = 0;
const pending = new Map();
const consoleLines = [];
ws.onmessage = (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id && pending.has(msg.id)) {
    pending.get(msg.id)(msg);
    pending.delete(msg.id);
  }
  if (msg.method === 'Runtime.consoleAPICalled') {
    const text = (msg.params.args || [])
      .map((a) => a.value ?? a.description ?? '')
      .join(' ');
    consoleLines.push(`${msg.params.type}: ${text}`);
  }
  if (msg.method === 'Runtime.exceptionThrown') {
    consoleLines.push(
      'EXCEPTION: ' +
        JSON.stringify(msg.params.exceptionDetails?.exception?.description ||
          msg.params.exceptionDetails?.text),
    );
  }
};

function send(method, params = {}) {
  const msgId = ++id;
  ws.send(JSON.stringify({ id: msgId, method, params }));
  return new Promise((resolve) => pending.set(msgId, resolve));
}

async function evaluate(expression) {
  const res = await send('Runtime.evaluate', {
    expression,
    awaitPromise: true,
    returnByValue: true,
  });
  return res.result?.result?.value;
}

await send('Runtime.enable');
await sleep(9000);

const dbs = await evaluate('indexedDB.databases()');
const storageKeys = await evaluate(
  'Object.keys(localStorage).filter(k => k.startsWith("math_fs:"))',
);
const hasWorker = await evaluate(
  'typeof SharedWorker !== "undefined"',
);

console.log('--- IndexedDB databases ---');
console.log(JSON.stringify(dbs, null, 2));
console.log('--- localStorage backup vault keys ---');
console.log(JSON.stringify(storageKeys));
console.log('--- SharedWorker supported: ' + hasWorker);
console.log('--- console / exceptions ---');
console.log(consoleLines.length ? consoleLines.join('\n') : '(none)');

ws.close();
chrome.kill();
process.exit(0);
