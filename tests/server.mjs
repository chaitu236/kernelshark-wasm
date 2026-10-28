import { createReadStream } from 'node:fs';
import { access, stat } from 'node:fs/promises';
import { createServer } from 'node:http';
import { extname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(process.env.KS_TEST_DIST || fileURLToPath(new URL('../out/wasm-release/dist', import.meta.url)));
await access(resolve(root, 'kernelshark.html')).catch(() => {
  throw new Error(`Missing browser build in ${root}. Run ./build.sh first, or set KS_TEST_DIST.`);
});

const contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.svg': 'image/svg+xml',
  '.txt': 'text/plain; charset=utf-8',
};

const server = createServer(async (request, response) => {
  response.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  response.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
  response.setHeader('X-Content-Type-Options', 'nosniff');
  response.setHeader('Cache-Control', 'no-store');

  try {
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    if (pathname === '/healthz') {
      response.writeHead(200, { 'Content-Type': 'text/plain' });
      response.end('ok\n');
      return;
    }

    const file = resolve(root, `.${pathname === '/' ? '/kernelshark.html' : pathname}`);
    if (!file.startsWith(`${root}${sep}`)) {
      response.writeHead(403).end();
      return;
    }

    const info = await stat(file);
    if (!info.isFile()) {
      response.writeHead(404).end();
      return;
    }

    response.writeHead(200, {
      'Content-Type': contentTypes[extname(file)] || 'application/octet-stream',
      'Content-Length': info.size,
    });
    if (request.method === 'HEAD') {
      response.end();
      return;
    }
    createReadStream(file).on('error', () => response.destroy()).pipe(response);
  } catch (error) {
    response.writeHead(error.code === 'ENOENT' ? 404 : 400).end();
  }
});

server.listen(8090, '127.0.0.1', () => {
  console.log(`Serving ${root} at http://127.0.0.1:8090`);
});

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => server.close(() => process.exit(0)));
}
