const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();

    await page.goto('http://localhost:3000', { waitUntil: 'load', timeout: 60000 });
    await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 30000 });

    // Fixed wait: flt-glass-pane shadow DOM is opaque to querySelector; 8s covers
    // CanvasKit WASM init + Firestore emulator data load
    await page.waitForTimeout(8000);
    await page.screenshot({ path: 'screenshots/home-screen.png' });

    await browser.close();
})();
