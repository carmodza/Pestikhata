import fs from 'node:fs/promises';
import {browserSession,pause} from './browser_driver.mjs';

const browser=await browserSession({mode:'smoke'});
const entryUpdatesOnly=process.argv.includes('--entry-updates');
await fs.mkdir('.tooling/previews',{recursive:true});
async function ready(){
  for(let i=0;i<120;i++){
    if(await browser.evaluate("document.getElementById('splash') === null"))break;
    if(i===119)throw Error('Flutter did not render its first frame');await pause(500);
  }
  await browser.evaluate("document.querySelector('flt-semantics-placeholder')?.click()");await pause(1500);
}
async function names(){return(await browser.send('Accessibility.getFullAXTree')).nodes.filter(n=>!n.ignored).map(n=>n.name?.value).filter(Boolean);}
async function expectText(text){
  for(let i=0;i<120;i++){if((await names()).some(n=>n.includes(text)))return;await pause(500);}
  const exceptions=browser.events.filter(e=>e.method==='Runtime.exceptionThrown').map(e=>e.params.exceptionDetails.exception?.description??e.params.exceptionDetails.text);
  throw Error(`Missing rendered text '${text}': ${(await names()).join(' | ')}\nExceptions: ${exceptions.join('\n')}`);
}
async function load(method,params={}){
  const start=browser.events.length;
  await browser.send(method,params);
  for(let i=0;i<120;i++){
    if(browser.events.slice(start).some(e=>e.method==='Page.loadEventFired')){await ready();return;}
    await pause(500);
  }
  throw Error(`Page load timed out: ${method}`);
}
try{
  await browser.send('Emulation.setEmulatedMedia',{features:[{name:'prefers-color-scheme',value:'light'}]});
  await ready();await expectText('Try local demo');
  await browser.screenshot('.tooling/previews/login-desktop.png');
  await browser.clickText('Try local demo');await expectText('Punjab Agri Traders');
  await browser.clickText('Seed demo data');await pause(2000);
  await expectText('Cash balance');await browser.screenshot('.tooling/previews/home-desktop.png');
  if(!entryUpdatesOnly){
  await load('Page.navigate',{url:browser.url+'/more'});await expectText('Stock');
  if((await names()).some(n=>n==='Inventory'||n==='Godam'))throw Error('Separate inventory/godam menu entries still exist');
  await browser.clickText('Stock');await expectText('All locations');
  await browser.clickText('Godams & transfers');await expectText('Main Godam');
  await browser.clickText('Items');await expectText('Sona Urea');
  await browser.clickText('Stock location All locations');await browser.clickText('Main Godam');
  await expectText('No stock in this location yet');
  await browser.clickText('Stock location Main Godam');await browser.clickText('All locations');await expectText('Sona Urea');
  console.log('PASS: merged stock navigation, tabs and location filtering.');
  for(const [route,label] of [
    ['/roznamcha','Opening balance'],['/stock','Sona Urea'],['/inventory','Sona Urea'],['/godam','Main Godam'],
    ['/inventory/urea','Batches & locations'],
    ['/rates','Update rate'],['/expenses','Add expense'],['/reports','Gross profit'],
    ['/backup','Local backup'],['/settings','Appearance'],['/users','Demo Owner'],
  ]){
    await load('Page.navigate',{url:browser.url+route});await expectText(label);
  }
  await load('Page.navigate',{url:browser.url+'/settings'});
  await browser.clickText('Roman Urdu');await expectText('Zabaan');
  await browser.clickText('English');await expectText('Language');
  await browser.clickText('Dark');await browser.screenshot('.tooling/previews/settings-dark.png');
  await browser.clickText('Light');
  }
  await load('Page.navigate',{url:browser.url});
  await browser.send('Emulation.setDeviceMetricsOverride',{width:390,height:844,deviceScaleFactor:1,mobile:true});await pause(800);
  await browser.screenshot('.tooling/previews/home-mobile.png');
  if(!entryUpdatesOnly){
  await browser.clickText('More');await browser.clickText('Stock');await expectText('Items');
  await browser.screenshot('.tooling/previews/stock-mobile.png');
  await browser.clickText('Godams & transfers');await expectText('Main Godam');
  await browser.screenshot('.tooling/previews/stock-godams-mobile.png');
  }
  await browser.clickText('Khata');await expectText('Farmer khata');await browser.screenshot('.tooling/previews/khata-mobile.png');
  const farmerName=(await names()).find(n=>n.includes('Muhammad Ali'));
  if(!farmerName)throw Error(`Farmer profile is missing from khata: ${(await names()).join(' | ')}`);
  await browser.clickText(farmerName);await expectText('Receive payment');
  await browser.clickText('Receive payment');await expectText('Pending receipts');await expectText('Remaining');
  await browser.screenshot('.tooling/previews/pending-payment-mobile.png');
  await load('Page.navigate',{url:browser.url+'/entry/crop'});
  await browser.clickText('Farmer');await expectText('Search / select a person');
  await browser.screenshot('.tooling/previews/source-picker-mobile.png');
  const sourceName=(await names()).find(n=>n.includes('Muhammad Ali'));
  await browser.clickText(sourceName);
  await browser.clickText('Search / select an item');await expectText('Wheat');
  const cropName=(await names()).find(n=>n.includes('Wheat'));
  await browser.clickText(cropName);
  await browser.send('Input.dispatchMouseEvent',{type:'mouseWheel',x:200,y:600,deltaX:0,deltaY:500});await pause(600);
  await expectText('Crop purchase & sale rates');await expectText('Rate later');
  await browser.screenshot('.tooling/previews/crop-rates-mobile.png');
  await load('Page.navigate',{url:browser.url});await ready();
  await browser.clickText('Entry');await expectText('New entry');await browser.screenshot('.tooling/previews/entry-dial-mobile.png');
  await load('Page.navigate',{url:browser.url});await expectText('Punjab Agri Traders');
  await browser.evaluate('navigator.serviceWorker.ready.then(()=>true)');
  for(let i=0;i<60;i++){if(await browser.evaluate('navigator.serviceWorker.controller !== null'))break;await pause(500);}
  if(!await browser.evaluate('navigator.serviceWorker.controller !== null'))throw Error('Offline service worker is not controlling the page');
  await browser.send('Network.emulateNetworkConditions',{offline:true,latency:0,downloadThroughput:0,uploadThroughput:0});
  await load('Page.reload');await expectText('Punjab Agri Traders');await expectText('Cash balance');
  await browser.screenshot('.tooling/previews/home-offline.png');
  const errors=browser.events.filter(e=>e.method==='Runtime.exceptionThrown').map(e=>e.params.exceptionDetails.exception?.description??e.params.exceptionDetails.text);
  if(errors.length)throw Error(`Browser exceptions:\n${errors.join('\n')}`);
  console.log(entryUpdatesOnly ? 'PASS: crop rates, immediate source picker, pending-payment mobile screen and offline SQLite reload.' : 'PASS: crop rates, immediate source picker, pending-payment screens, merged stock, all shop modules, languages/themes, desktop/mobile and offline SQLite reload.');
}finally{await browser.close();}
