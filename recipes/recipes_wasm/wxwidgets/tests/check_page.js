const fs = require('fs');
const http = require('http');
const path = require('path');
const { chromium } = require('playwright');

const workDir = process.argv[2] || '.';
const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm' };

const server = http.createServer((req, res) => {
  const file = path.join(workDir, decodeURIComponent(req.url.split('?')[0]));
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end('not found'); return; }
    res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  });
});

(async () => {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;
  const messages = [];
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 800, height: 600 } });
    page.on('console', (msg) => messages.push(msg.text()));
    await page.goto(`http://127.0.0.1:${port}/app.html`);
    const canvas = page.locator('canvas#canvas');
    await canvas.waitFor({ state: 'visible', timeout: 60000 });
    await page.waitForFunction(
      () => document.querySelector('canvas#canvas').width > 0, null, { timeout: 60000 });
    const box = await canvas.boundingBox();
    await page.mouse.click(box.x + 60, box.y + 45);
    for (let i = 0; i < 600; i++) {
      if (messages.includes('TEST_PAINT_OK') && messages.includes('TEST_CLICK_OK')) break;
      await page.waitForTimeout(100);
    }
  } finally {
    await browser.close();
    server.close();
  }
  const missing = ['TEST_PAINT_OK', 'TEST_CLICK_OK'].filter((m) => !messages.includes(m));
  if (missing.length) {
    console.log('MISSING ' + missing.join(', '));
    console.log('captured console output:\n' + messages.join('\n'));
    process.exit(1);
  }
  console.log('browser test OK: paint and click both observed');
})();
