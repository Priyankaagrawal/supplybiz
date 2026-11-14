// T-050: local synthetic HTTP + actual Android WorkManager/process-kill probe.
// No OTP/provider delivery, PostgreSQL financial posting or production data claim.
import { createServer } from 'node:http';
import { execFileSync } from 'node:child_process';
import { deepStrictEqual, equal, ok } from 'node:assert/strict';
import { setTimeout as delay } from 'node:timers/promises';
const device = process.env.ANDROID_SERIAL || 'emulator-5554';
ok(/^emulator-\d+$/.test(device), 'This process-kill probe targets an Android emulator only.');
const pkg = 'in.supplybiz.mobile.dev';
const adb = (...args) => execFileSync('adb', ['-s', device, ...args], { encoding: 'utf8', timeout: 30000 }).trim();
const row = {
  id:'77777777-7777-4777-8777-777777777777', orderNo:'ORD00000001', vendorId:'55555555-5555-4555-8555-555555555555',
  status:'ACCEPTED',version:1,deliveryDate:'2026-11-14',timeSlot:'07:00-08:00',totalPaise:'12020',paymentMode:'POD_CASH',paymentStatus:'UNPAID',source:'APP',createdAt:'2026-11-13T10:00:00Z',
};
const detail = () => ({...row,vendorName:'Synthetic vendor',customerName:'Synthetic customer',customerMobile:'+919000000000',
  address:{id:'11111111-1111-4111-8111-111111111111',label:'Synthetic',line1:'Synthetic',line2:'Synthetic',landmark:'',city:'Synthetic',state:'Synthetic',pincode:'560001',latitude:12.97,longitude:77.59,isDefault:true},
  items:[{productId:'22222222-2222-4222-8222-222222222222',name:'Synthetic milk',unitValue:'1',unitType:'L',qty:2,unitPricePaise:'6010',lineTotalPaise:'12020'}],
  timeline:[],subtotalPaise:'12020',deliveryChargePaise:'0',discountPaise:'0',rejectReason:null,cancelReason:null,failReason:null,
});
const replay = new Map(), attempts = new Map(), results = [];
let ready=false, commits=0, refreshes=0, refreshReuses=0, token='synthetic-refresh-0', failure, generation, cleanup=false, cleaned=false;
const server = createServer(async (req,res) => {
  try {
    const data=[]; for await (const part of req) data.push(part);
    const body=data.length?JSON.parse(Buffer.concat(data).toString()):{};
    const path=req.url.split('?')[0];
    const reply=(value,status=200)=>{res.writeHead(status,{'content-type':'application/json'});res.end(JSON.stringify(value));};
    if(path==='/probe-mode')return reply({cleanup});
    if(path==='/probe-cleaned'){cleaned=true;return reply({});}
    if(path==='/probe-begin') {
      generation=body.generation;ready=false;commits=0;refreshes=0;refreshReuses=0;token='synthetic-refresh-0';failure=undefined;
      replay.clear();attempts.clear();results.length=0;row.status='ACCEPTED';row.version=1;row.paymentStatus='UNPAID';return reply({});
    }
    if(path==='/probe-ready'){if(body.generation===generation)ready=true;return reply({});}
    if(path==='/worker-result'){if(body.generation===generation)results.push(body);return reply({});}
    if(path==='/api/v1/auth/refresh') {
      equal(req.headers['x-platform'],'android');equal(req.headers['x-app-version'],'0.1.0');
      if(body.refreshToken!==token){refreshReuses++;return reply({code:'REFRESH_REUSED'},401);}
      token=`synthetic-refresh-${++refreshes}`;
      return reply({accessToken:`synthetic-access-${refreshes}`,refreshToken:token,expiresInSec:900,
        user:{id:'11111111-1111-4111-8111-111111111111',mobile:'+919000000000',name:null,language:'EN',roles:['VENDOR'],activeRole:'VENDOR'}});
    }
    equal(req.headers['x-platform'],'android');equal(req.headers['x-app-version'],'0.1.0');
    ok(/^Bearer synthetic-(?:probe-access|access-\d+)$/.test(req.headers.authorization||''));
    if(path==='/api/v1/vendor/deliveries') {
      return reply({serverTime:new Date().toISOString(),businessDate:'2026-11-14',deliveryDate:'2026-11-14',counts:{ALL:1,PENDING:row.status==='ACCEPTED'?1:0,PREPARING:0,OUT_FOR_DELIVERY:row.status==='OUT_FOR_DELIVERY'?1:0,DELIVERED:row.status==='DELIVERED'?1:0,FAILED:0},items:[detail()],total:1});
    }
    if(path.endsWith('/transitions')) {
      const key=req.headers['idempotency-key'];ok(key);attempts.set(key,(attempts.get(key)||0)+1);
      ok(Number.isFinite(Date.parse(body.clientCreatedAt)));
      if(replay.has(key)){deepStrictEqual(body,replay.get(key).body);return reply(replay.get(key).result,201);}
      equal(body.version,row.version);
      equal(body.to,commits===0?'OUT_FOR_DELIVERY':'DELIVERED');
      if(commits===1)deepStrictEqual(body.payment,{collected:true,method:'UPI',amountPaise:'12020'});
      row.status=body.to;row.version++;if(row.status==='DELIVERED')row.paymentStatus='PAID';
      commits++;replay.set(key,{body,result:{...row}});
      if(commits===1){req.socket.destroy();return;}
      return reply(row,201);
    }
    reply({code:'UNKNOWN_PROBE_PATH'},404);
  } catch(e) { failure=e;res.writeHead(500);res.end('{}'); }
});
async function until(predicate,ms) {
  const end=Date.now()+ms;
  while(!predicate()){if(failure)throw failure;if(Date.now()>end)throw Error('Android background probe timed out');await delay(500);}
}
try {
  await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(33175,'127.0.0.1',resolve);});
  console.log('Synthetic T-050 fixture ready on localhost:33175.');
  adb('shell','am','start','-n',`${pkg}/in.supplybiz.supplybiz_mobile.MainActivity`);
  await until(()=>ready,90000);equal(commits,1);
  adb('shell','input','keyevent','KEYCODE_HOME');await delay(1000);
  adb('shell','am','kill',pkg);await delay(1000);
  let pid='';try{pid=adb('shell','pidof',pkg);}catch{}
  if(pid){ok(/^\d+$/.test(pid));adb('shell','run-as',pkg,'kill','-9',pid);await delay(1000);try{pid=adb('shell','pidof',pkg);}catch{pid='';}}
  equal(pid,'','The probe app process must be gone before background execution.');
  console.log('Foreground process killed; waiting for scheduled Android workers.');
  await until(()=>results.length>=2,180000);
  if(failure)throw failure;
  equal(commits,2);equal(refreshes,1);equal(refreshReuses,0);equal(replay.size,2);equal(row.status,'DELIVERED');
  equal(Math.max(...attempts.values()),2);
  ok(results.every(r=>r.done===true&&r.remaining===0));
  cleanup=true;
  adb('shell','am','start','-n',`${pkg}/in.supplybiz.supplybiz_mobile.MainActivity`);
  await until(()=>cleaned,90000);
  console.log('PASS: actual process kill → two headless workers; one serialized refresh, same-key FIFO replay, one synthetic payment, empty encrypted queue and Android version headers.');
} finally {
  try{adb('shell','am','force-stop',pkg);}catch{}
  server.closeAllConnections();await new Promise(resolve=>server.close(resolve));
}
