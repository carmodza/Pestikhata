import {spawn} from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';
import http from 'node:http';

export const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
export async function browserSession({root='build/web',width=1280,height=900,mode='preview'}={}){
  const server=http.createServer(async(req,res)=>{
    try{
      let relative=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
      if(!path.extname(relative))relative='/index.html';
      const base=path.resolve(root),file=path.resolve(base,'.'+relative);
      if(!file.startsWith(base+path.sep)){res.writeHead(403);res.end();return;}
      const content=await fs.readFile(file);
      const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm',
        '.svg':'image/svg+xml','.png':'image/png','.ttf':'font/ttf','.otf':'font/otf','.css':'text/css'}[path.extname(file)]??'application/octet-stream';
      res.writeHead(200,{'Content-Type':mime,'Cross-Origin-Opener-Policy':'same-origin-allow-popups','Cache-Control':'no-cache'});res.end(content);
    }catch{res.writeHead(404);res.end('Not found');}
  });
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const url=`http://127.0.0.1:${server.address().port}`;
  const profile=path.resolve(`.tooling/chrome-${mode}-${Date.now()}`);
  await fs.mkdir(profile,{recursive:true});
  const chrome=spawn('C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',[
    '--headless=new','--no-first-run','--no-default-browser-check','--disable-background-networking',
    '--use-angle=swiftshader','--enable-unsafe-swiftshader','--remote-debugging-port=0',`--user-data-dir=${profile}`,'about:blank'],
    {windowsHide:true,stdio:'ignore'});
  let port;
  for(let i=0;i<100;i++){try{port=Number((await fs.readFile(path.join(profile,'DevToolsActivePort'),'utf8')).split('\n')[0]);break;}catch{await pause(100);}}
  if(!port){chrome.kill();server.close();throw Error('Chrome DevTools did not start');}
  const response=await fetch(`http://127.0.0.1:${port}/json/new?${encodeURIComponent(url)}`,{method:'PUT'});
  const target=await response.json(),socket=new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve,reject)=>{socket.addEventListener('open',resolve,{once:true});socket.addEventListener('error',reject,{once:true});});
  let next=1;const pending=new Map(),events=[];
  socket.addEventListener('message',event=>{
    const message=JSON.parse(event.data);
    if(message.id){const waiter=pending.get(message.id);pending.delete(message.id);
      if(message.error)waiter?.reject(Error(JSON.stringify(message.error)));else waiter?.resolve(message.result);
    }else events.push(message);
  });
  function send(method,params={}){const id=next++;return new Promise((resolve,reject)=>{
    const timeout=setTimeout(()=>{pending.delete(id);reject(Error(`CDP timeout: ${method}`));},30000);
    pending.set(id,{resolve:r=>{clearTimeout(timeout);resolve(r);},reject:e=>{clearTimeout(timeout);reject(e);}});
    socket.send(JSON.stringify({id,method,params}));
  });}
  async function evaluate(expression){const result=await send('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});
    if(result.exceptionDetails)throw Error(result.exceptionDetails.exception?.description??result.exceptionDetails.text);
    return result.result?.value;}
  async function clickText(text){
    const tree=await send('Accessibility.getFullAXTree');
    const node=tree.nodes.find(n=>!n.ignored&&n.name?.value===text&&n.backendDOMNodeId);
    if(!node)throw Error(`Missing accessible control '${text}'. Available: ${tree.nodes.filter(n=>!n.ignored).map(n=>n.name?.value).filter(Boolean).join(' | ')}`);
    const {model}=await send('DOM.getBoxModel',{backendNodeId:node.backendDOMNodeId});
    const x=(model.content[0]+model.content[4])/2,y=(model.content[1]+model.content[5])/2;
    await send('Input.dispatchMouseEvent',{type:'mousePressed',x,y,button:'left',clickCount:1});
    await send('Input.dispatchMouseEvent',{type:'mouseReleased',x,y,button:'left',clickCount:1});await pause(600);
  }
  async function screenshot(file){const result=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});await fs.writeFile(file,Buffer.from(result.data,'base64'));}
  async function close(){try{await send('Page.close');}catch{}socket.close();chrome.kill();await new Promise(resolve=>server.close(resolve));}
  await send('Page.enable');await send('Runtime.enable');await send('Network.enable');await send('Accessibility.enable');
  await send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:width<600});
  await send('Page.navigate',{url});
  return {send,evaluate,clickText,screenshot,close,url,events};
}
