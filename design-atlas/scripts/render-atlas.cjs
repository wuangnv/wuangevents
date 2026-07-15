const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

function loadPlaywright() {
  try { return require("playwright"); } catch {}
  const runtimeModules = process.env.CODEX_NODE_MODULES || "C:\\Users\\MIIKEY\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\node_modules";
  return require(path.join(runtimeModules, "playwright"));
}

const { chromium } = loadPlaywright();
const root = path.resolve(__dirname, "..");
const output = path.join(root, "output");
const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"));
const node = process.execPath;
const port = Number(process.env.ATLAS_PORT || 4180);
const baseUrl = `http://127.0.0.1:${port}`;

fs.rmSync(output, { recursive: true, force: true });
fs.mkdirSync(path.join(output, "screens"), { recursive: true });

const server = spawn(node, [path.join(__dirname, "serve-atlas.cjs")], {
  cwd: root,
  env: { ...process.env, ATLAS_PORT: String(port) },
  stdio: ["ignore", "pipe", "pipe"]
});

const wait = ms => new Promise(resolve => setTimeout(resolve, ms));

async function waitForServer() {
  for (let attempt = 0; attempt < 50; attempt++) {
    try {
      const response = await fetch(baseUrl);
      if (response.ok) return;
    } catch {}
    await wait(100);
  }
  throw new Error("Atlas server không sẵn sàng");
}

async function run() {
  await waitForServer();
  const browser = await chromium.launch({ headless: true });
  const errors = [];
  const viewports = [
    { width: 390, height: 844, name: "mobile" },
    { width: 768, height: 1024, name: "tablet" },
    { width: 1366, height: 800, name: "desktop" },
    { width: 1920, height: 1080, name: "wide" }
  ];

  try {
    for (const screen of manifest) {
      const page = await browser.newPage({ viewport: { width: 1366, height: 800 }, deviceScaleFactor: 1 });
      const consoleErrors = [];
      page.on("console", message => { if (message.type() === "error") consoleErrors.push(message.text()); });
      await page.goto(`${baseUrl}/?screen=${screen.id}&mode=render`, { waitUntil: "networkidle" });
      await page.screenshot({ path: path.join(output, "screens", `${String(screen.index).padStart(2, "0")}-${screen.id}.png`), fullPage: false });
      if (consoleErrors.length) errors.push(`${screen.id}: console ${consoleErrors.join(" | ")}`);
      for (const viewport of viewports) {
        await page.setViewportSize({ width: viewport.width, height: viewport.height });
        const geometry = await page.evaluate(() => ({
          documentWidth: document.documentElement.scrollWidth,
          viewportWidth: document.documentElement.clientWidth,
          screenCount: document.querySelectorAll(".screen").length,
          title: document.title
        }));
        if (geometry.documentWidth > geometry.viewportWidth + 1) errors.push(`${screen.id}@${viewport.name}: overflow ngang ${geometry.documentWidth - geometry.viewportWidth}px`);
        if (geometry.screenCount !== 1) errors.push(`${screen.id}@${viewport.name}: render ${geometry.screenCount} screen`);
        if (!geometry.title.includes("WuangEvents")) errors.push(`${screen.id}@${viewport.name}: thiếu title`);
      }
      await page.close();
    }

    const overview = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
    await overview.goto(baseUrl, { waitUntil: "networkidle" });
    await overview.screenshot({ path: path.join(output, "atlas-overview.png"), fullPage: true });
    await overview.close();
  } finally {
    await browser.close();
  }

  const report = { screens: manifest.length, viewports: viewports.map(viewport => viewport.name), errors };
  fs.writeFileSync(path.join(output, "qa-report.json"), JSON.stringify(report, null, 2));
  if (errors.length) throw new Error(errors.join("\n"));
  process.stdout.write(`Render đạt: ${manifest.length} màn hình x ${viewports.length} viewport\n`);
}

run().catch(error => {
  process.stderr.write(error.stack + "\n");
  process.exitCode = 1;
}).finally(() => {
  server.kill();
});
