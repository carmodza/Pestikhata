import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const root='build/web';
if(!fs.existsSync(`${root}/index.html`))throw Error('Run flutter build web first');
const files=[];
function walk(dir){for(const entry of fs.readdirSync(dir,{withFileTypes:true})){const file=path.join(dir,entry.name);if(entry.isDirectory())walk(file);else files.push(file.replaceAll('\\','/').slice(root.length+1));}}
walk(root);
const assets=files.filter(f=>!['sw.js','flutter_service_worker.js'].includes(f)&&!f.endsWith('.map'));
const hash=crypto.createHash('sha256');
for(const file of assets){hash.update(file);hash.update(fs.readFileSync(`${root}/${file}`));}
const version=hash.digest('hex').slice(0,16);
const script=`// Generated; no user data or authenticated API responses are cached here.
const CACHE='pestikhata-${version}';
const ASSETS=${JSON.stringify(assets)};
self.addEventListener('install',event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(ASSETS))));
self.addEventListener('activate',event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('pestikhata-')&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',event=>{
 const url=new URL(event.request.url);
 if(event.request.method!=='GET'||url.origin!==self.location.origin)return;
 const relative=url.pathname.slice(new URL(self.registration.scope).pathname.length);
 if(event.request.mode==='navigate'){
   event.respondWith(fetch(event.request).catch(()=>caches.open(CACHE).then(c=>c.match('index.html'))));return;
 }
 if(ASSETS.includes(relative))event.respondWith(caches.open(CACHE).then(async cache=>(await cache.match(relative))||fetch(event.request)));
});
`;
fs.writeFileSync(`${root}/sw.js`,script);
console.log(`Offline shell ${version}: ${assets.length} local assets.`);
