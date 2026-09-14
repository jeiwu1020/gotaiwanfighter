// Optional deployment handoff. Not deployed or tested against a live Cloudflare account.
// R2 holds the >25 MiB WASM; no Pages static-asset size assumption.
export default {
  async fetch(request, env) {
    if (!['GET', 'HEAD'].includes(request.method)) return new Response('Method not allowed', { status: 405 });
    const key = new URL(request.url).pathname.replace(/^\/+/, '') || 'index.html';
    const object = await env.GAME_ASSETS.get(key);
    if (!object) return new Response('Not found', { status: 404 });
    const headers = new Headers();
    object.writeHttpMetadata(headers);
    const types = { html: 'text/html; charset=utf-8', js: 'text/javascript', wasm: 'application/wasm', pck: 'application/octet-stream', png: 'image/png' };
    headers.set('Content-Type', types[key.split('.').pop()] || 'application/octet-stream');
    headers.set('ETag', object.httpEtag);
    headers.set('Cache-Control', 'no-cache');
    headers.set('X-Content-Type-Options', 'nosniff');
    if (request.headers.get('If-None-Match') === object.httpEtag) return new Response(null, { status: 304, headers });
    return new Response(request.method === 'HEAD' ? null : object.body, { headers });
  }
};
