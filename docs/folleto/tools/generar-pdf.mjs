// Genera los PDF (oscuro y claro) de un folleto usando Brave/Chromium vía CDP.
//
// Requiere: Brave (o Chrome/Chromium) y Node 22+.
// Uso:
//   1) Lanza el navegador con depuración remota apuntando al HTML:
//        brave --headless=new --no-sandbox --disable-gpu \
//          --remote-debugging-port=9223 --user-data-dir=/tmp/bp \
//          "file://$PWD/<archivo>.html" &
//   2) Ejecuta:
//        node tools/generar-pdf.mjs 9223 <archivo>.html <prefijo-salida>
//
// Ejemplo:
//   node tools/generar-pdf.mjs 9223 dirty-road-triptico.html DirtyRoad-triptico
//   → DirtyRoad-triptico-oscuro.pdf y DirtyRoad-triptico-claro.pdf

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.resolve(here, '..');
const port = process.argv[2] || '9223';
const htmlName = process.argv[3] || 'dirty-road-folleto.html';
const prefix = process.argv[4] || 'DirtyRoad-folleto';
const base = `http://127.0.0.1:${port}`;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

class CDP {
  constructor(ws) {
    this.ws = ws; this.id = 0; this.p = new Map();
    this.ready = new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });
    ws.onmessage = (e) => {
      const m = JSON.parse(e.data);
      if (m.id && this.p.has(m.id)) {
        const { res, rej } = this.p.get(m.id); this.p.delete(m.id);
        m.error ? rej(new Error(JSON.stringify(m.error))) : res(m.result);
      }
    };
  }
  send(method, params = {}) {
    const id = ++this.id;
    return new Promise((res, rej) => { this.p.set(id, { res, rej }); this.ws.send(JSON.stringify({ id, method, params })); });
  }
}

async function target() {
  for (let i = 0; i < 120; i++) {
    try {
      const l = await (await fetch(base + '/json/list')).json();
      const p = l.find((t) => t.type === 'page' && t.webSocketDebuggerUrl);
      if (p) return p;
    } catch {}
    await sleep(200);
  }
  throw new Error('No se encontró el target del navegador (¿abierto con --remote-debugging-port?)');
}

const page = await target();
const c = new CDP(new WebSocket(page.webSocketDebuggerUrl));
await c.ready;
await c.send('Page.enable');
await c.send('Runtime.enable');
for (let i = 0; i < 120; i++) {
  const { result } = await c.send('Runtime.evaluate', {
    expression: `document.readyState==='complete' && document.fonts.status==='loaded' && Array.from(document.images).every(i=>i.complete)`,
    returnByValue: true,
  });
  if (result.value) break;
  await sleep(200);
}
await sleep(500);

async function printTo(file) {
  const { data } = await c.send('Page.printToPDF', {
    printBackground: true, preferCSSPageSize: true,
    marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0,
  });
  fs.writeFileSync(file, Buffer.from(data, 'base64'));
  console.log('PDF:', path.basename(file), Math.round(fs.statSync(file).size / 1024) + ' KB');
}

await printTo(path.join(outDir, `${prefix}-oscuro.pdf`));
await c.send('Runtime.evaluate', { expression: `document.body.classList.add('light')` });
await sleep(600);
await printTo(path.join(outDir, `${prefix}-claro.pdf`));
await c.send('Browser.close').catch(() => {});
console.log('Listo ·', htmlName);
