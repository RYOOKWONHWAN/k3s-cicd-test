// 빌드된 프론트(dist)를 보여 주고, 배포 정보를 알려 주는 작은 서버 (외부 패키지 없음)
import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';

const PORT = Number(process.env.PORT) || 8080;
const DIST = path.resolve('dist');
const STARTED_AT = new Date().toISOString();

// CI 가 이미지를 만들 때 넣어 주는 값 (로컬에서는 기본값)
const INFO = {
  version: process.env.APP_VERSION || 'dev',
  commit: process.env.APP_COMMIT || 'local',
  buildTime: process.env.APP_BUILD_TIME || 'unknown',
};

const TYPES = new Map([
  ['.html', 'text/html; charset=utf-8'],
  ['.js', 'text/javascript; charset=utf-8'],
  ['.css', 'text/css; charset=utf-8'],
  ['.svg', 'image/svg+xml'],
  ['.png', 'image/png'],
  ['.ico', 'image/x-icon'],
  ['.json', 'application/json; charset=utf-8'],
]);

function sendJson(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' });
  res.end(JSON.stringify(body));
}

async function sendFile(res, filePath) {
  const data = await fs.readFile(filePath);
  res.writeHead(200, { 'Content-Type': TYPES.get(path.extname(filePath)) || 'application/octet-stream' });
  res.end(data);
}

async function serveStatic(req, res) {
  let urlPath;
  try {
    urlPath = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  } catch {
    return sendJson(res, 400, { error: 'bad url' });
  }
  const filePath = path.join(DIST, urlPath);
  // dist 밖의 파일은 못 읽게 막는다
  if (filePath !== DIST && !filePath.startsWith(DIST + path.sep)) return sendJson(res, 403, { error: 'forbidden' });
  try {
    const stat = await fs.stat(filePath);
    return await sendFile(res, stat.isDirectory() ? path.join(filePath, 'index.html') : filePath);
  } catch {
    // 없는 주소는 첫 화면으로 (SPA)
    try {
      return await sendFile(res, path.join(DIST, 'index.html'));
    } catch {
      return sendJson(res, 404, { error: 'not built. run npm run build' });
    }
  }
}

const server = http.createServer((req, res) => {
  if (req.url === '/api/health') return sendJson(res, 200, { ok: true });
  if (req.url === '/api/info') {
    return sendJson(res, 200, { ...INFO, pod: os.hostname(), startedAt: STARTED_AT, now: new Date().toISOString() });
  }
  if (req.method !== 'GET' && req.method !== 'HEAD') return sendJson(res, 405, { error: 'method not allowed' });
  serveStatic(req, res).catch((err) => {
    console.error(err);
    if (!res.headersSent) sendJson(res, 500, { error: 'server error' });
  });
});

server.listen(PORT, () => console.log(`listening on :${PORT} (version ${INFO.version}, commit ${INFO.commit})`));

// 쿠버네티스가 파드를 끌 때(SIGTERM) 받던 요청은 마저 처리하고 끈다
function shutdown() {
  console.log('shutting down');
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 5000).unref();
}
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
