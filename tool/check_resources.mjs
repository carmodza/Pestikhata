import fs from 'node:fs';
import path from 'node:path';
const en=JSON.parse(fs.readFileSync('lib/l10n/app_en.arb','utf8'));
const ur=JSON.parse(fs.readFileSync('lib/l10n/app_ur.arb','utf8'));
const keys=Object.keys(en).filter(k=>!k.startsWith('@'));
if(JSON.stringify(keys)!==JSON.stringify(Object.keys(ur).filter(k=>!k.startsWith('@'))))throw Error('Locale keys differ');
for(const key of keys){if(!en[key]||!ur[key])throw Error(`Empty translation: ${key}`);}
function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(entry=>entry.isDirectory()?walk(path.join(dir,entry.name)):[path.join(dir,entry.name)]);}
const missing=new Set();
for(const file of walk('lib').filter(f=>f.endsWith('.dart')&&!f.endsWith('.g.dart'))){
  for(const match of fs.readFileSync(file,'utf8').matchAll(/\.tr\('([^']+)'\)/g)){if(!(match[1]in en))missing.add(match[1]);}
}
if(missing.size)throw Error(`Missing literal localization keys: ${[...missing].join(', ')}`);
for(const file of ['firebase.json','firestore.indexes.json','web/manifest.json','config/firebase.example.json'])JSON.parse(fs.readFileSync(file,'utf8'));
if(fs.readFileSync('web/sqlite3.wasm').subarray(0,4).toString('hex')!=='0061736d')throw Error('Missing SQLite WASM binary');
for(const icon of ['web/icons/Icon-192.png','web/icons/Icon-512.png','web/icons/apple-touch-icon.png']){
  if(fs.readFileSync(icon).subarray(0,8).toString('hex')!=='89504e470d0a1a0a')throw Error(`Invalid PNG ${icon}`);
}
console.log(`PASS: ${keys.length} matching English/Roman Urdu strings, literal UI keys, JSON configuration, WASM and PWA icons.`);
