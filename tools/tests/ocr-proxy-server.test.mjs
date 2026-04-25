import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { setTimeout as delay } from 'node:timers/promises';

const serverScript = fileURLToPath(new URL('../ocr-proxy-server.mjs', import.meta.url));

async function waitForHealth(baseURL, attempts = 40) {
  for (let i = 0; i < attempts; i += 1) {
    try {
      const response = await fetch(`${baseURL}/health`);
      if (response.ok) {
        return;
      }
    } catch {
      // retry
    }
    await delay(100);
  }
  throw new Error(`Proxy did not become healthy at ${baseURL}`);
}

async function withProxyServer(run) {
  const port = 8800 + Math.floor(Math.random() * 500);
  const baseURL = `http://127.0.0.1:${port}`;
  const child = spawn(process.execPath, [serverScript], {
    env: {
      ...process.env,
      PORT: String(port),
    },
    stdio: 'ignore',
  });

  try {
    await waitForHealth(baseURL);
    await run(baseURL);
  } finally {
    if (!child.killed) {
      child.kill('SIGTERM');
    }
    await Promise.race([
      new Promise(resolve => child.once('exit', resolve)),
      delay(1000),
    ]);
  }
}

test('accepts text-only enhancement requests', async () => {
  await withProxyServer(async baseURL => {
    const response = await fetch(`${baseURL}/api/ocr`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ words: ['腕', '機会'] }),
    });

    assert.equal(response.status, 200);
    const payload = await response.json();
    assert.equal(payload.type, 'message');
    assert.equal(Array.isArray(payload.content), true);
  });
});

test('rejects legacy image payloads so the proxy stays text-only', async () => {
  await withProxyServer(async baseURL => {
    const response = await fetch(`${baseURL}/api/ocr`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        words: [],
        imageBase64: 'ZmFrZS1pbWFnZQ==',
        mimeType: 'image/png',
      }),
    });

    assert.equal(response.status, 400);
    const payload = await response.json();
    assert.match(payload.error, /text-only|words/i);
  });
});
