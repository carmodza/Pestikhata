import fs from 'node:fs/promises';
import path from 'node:path';
import {browserSession} from './browser_driver.mjs';
const browser=await browserSession({root:'web',mode:'brand'});
try{
  const svg=(await fs.readFile('web/icons/pestikhata.svg')).toString('base64');
  const targets=[
    ...[['mdpi',48],['hdpi',72],['xhdpi',96],['xxhdpi',144],['xxxhdpi',192]].map(([density,size])=>({file:`android/app/src/main/res/mipmap-${density}/ic_launcher.png`,size})),
    {file:'web/icons/Icon-192.png',size:192},{file:'web/icons/Icon-512.png',size:512},
    {file:'web/icons/apple-touch-icon.png',size:180},{file:'web/favicon.png',size:32},
  ];
  const catalog=JSON.parse(await fs.readFile('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json','utf8'));
  for(const item of catalog.images){if(item.filename)targets.push({file:`ios/Runner/Assets.xcassets/AppIcon.appiconset/${item.filename}`,size:Math.round(Number(item.size.split('x')[0])*Number(item.scale.replace('x',''))),opaque:true});}
  for(const item of targets){
    const png=await browser.evaluate(`(async()=>{const img=new Image();img.src='data:image/svg+xml;base64,${svg}';await img.decode();const c=document.createElement('canvas');c.width=c.height=${item.size};const ctx=c.getContext('2d');${item.opaque?"ctx.fillStyle='#24794e';ctx.fillRect(0,0,c.width,c.height);":''}ctx.drawImage(img,0,0,c.width,c.height);return c.toDataURL('image/png').split(',')[1];})()`);
    await fs.mkdir(path.dirname(item.file),{recursive:true});await fs.writeFile(item.file,Buffer.from(png,'base64'));
  }
  const png=Buffer.from(await browser.evaluate(`(async()=>{const img=new Image();img.src='data:image/svg+xml;base64,${svg}';await img.decode();const c=document.createElement('canvas');c.width=c.height=256;c.getContext('2d').drawImage(img,0,0,256,256);return c.toDataURL('image/png').split(',')[1];})()`),'base64');
  const header=Buffer.alloc(22);header.writeUInt16LE(1,2);header.writeUInt16LE(1,4);header.writeUInt16LE(1,10);header.writeUInt16LE(32,12);header.writeUInt32LE(png.length,14);header.writeUInt32LE(22,18);
  await fs.writeFile('windows/runner/resources/app_icon.ico',Buffer.concat([header,png]));
  console.log(`Created ${targets.length+1} PestiKhata platform icons from the repository SVG.`);
}finally{await browser.close();}
